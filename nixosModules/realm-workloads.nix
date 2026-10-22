# SPIFFE workload networking (realm).
#
# Goal: a service can reach its declared peers over authenticated TLS and has no
# route to anything else. Each workload is therefore a small stack of processes
# rather than one trusted daemon:
#
#   application (private namespace, no route out)
#     -> egress Unix socket      systemd-socket-proxyd, or the app directly
#     -> ghostunnel client       runs as realm-<name>, holds the SVID
#     -> direct TLS connection   target compiled from the ingress catalog
#     -> remote ghostunnel       checks the caller against allowedIDs
#     -> ingress socket          adapter in the backend's namespace
#
# The application holds no key and, on the proxy path, never sees the SPIRE
# Agent socket. Authorization is stated by the receiver: an ingress names the
# exact SPIFFE IDs it accepts and ghostunnel enforces that list. DNS only selects
# a candidate address, so it cannot change the expected identity.
#
# Declare a workload next to the service it describes in mod/:
#
#   realm.workloads.example = {
#     unit = "example.service";        # default: <name>.service
#     user = "example";
#     group = "example";
#
#     egress.loki = {                  # this workload acts as a client
#       service = "loki";              # SRV name loki.svc.mesh.nyaw.xyz
#       verifyID = "spiffe://nyaw.xyz/service/loki";
#       localPort = 13030;             # optional loopback adapter
#     };
#
#     ingress.http = {                 # this workload acts as a server
#       port = 18080;
#       target = "127.0.0.1:8080";
#       privateLoopback = true;
#       service = "example";           # name published in DNS
#       allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
#     };
#   };
#
# Options that relax the default isolation (runtime, privateNetwork, native,
# hostLoopback) are explained where they are consumed below.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.realm;
  # A declaration with enable = false contributes no units at all.
  active = lib.filterAttrs (_: w: w.enable) cfg.workloads;
  # One static binary covers the socket bridges and container adapters. It has no interpreter and no library dependencies, so the
  # same artifact also runs inside container images.
  helper = cfg.helperPackage;
  # Compile a direct destination from the same catalog that publishes CoreDNS.
  # Multiple instances require an explicit target instead of implicit selection.
  destinations =
    service:
    lib.concatLists (
      lib.mapAttrsToList (
        _: published:
        lib.optional (published ? ${service} && published.${service}.port != null) (
          let
            endpoint = published.${service};
          in
          "[${endpoint.address}]:${toString endpoint.port}"
        )
      ) cfg.serviceDiscovery.catalog
    );
  # systemd-socket-proxyd bridges one systemd socket to a plain TCP or Unix
  # target. It is what connects a workload-local loopback address to an
  # authenticated socket, and it always runs inside a private namespace.
  proxy = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd";
  # socket-proxyd splits the target at the last colon and hands the host part to
  # getaddrinfo, so bracketed IPv6 literals must lose their brackets here.
  proxyTarget =
    target:
    let
      ipv6 = builtins.match "[[]([^]]+)[]]:([0-9]+)" target;
    in
    if ipv6 == null then target else "${builtins.elemAt ipv6 0}:${builtins.elemAt ipv6 1}";
  # Naming contract: realm-<name> is the proxy account of workload <name>,
  # w.unit is the application, and /run/realm/<name> is the only runtime path
  # the two sides share.
  appName = w: lib.removeSuffix ".service" w.unit;
  proxyUser = name: "realm-${name}";
  base = name: "/run/realm/${name}";
  egressPath = name: route: "${base name}/egress/${route}.sock";
  ingressPath = name: route: "${base name}/ingress/${route}.sock";
  endpointType = types.submodule (
    { name, ... }:
    {
      options = {
        # Service name in the declarative ingress catalog.
        service = mkOption { type = types.str; };
        # Exact URI SAN expected from the peer; DNS cannot override it.
        verifyID = mkOption { type = types.str; };
        target = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Fixed TLS destination as host:port or unix:/path, instead of the declarative catalog.";
        };
        # Use an existing socket instead of the generated path, when another
        # module owns the listener.
        socket = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        localPort = mkOption {
          type = types.nullOr types.port;
          default = null;
          description = "Optional loopback adapter inside the workload namespace.";
        };
      };
    }
  );
  ingressType = types.submodule {
    options = {
      # Port on the node's mesh address; the published SRV record uses it.
      port = mkOption { type = types.port; };
      # Plaintext backend the ingress process dials after terminating mTLS.
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      native = mkOption {
        type = types.bool;
        default = false;
        description = "The application terminates SPIFFE mTLS and enforces allowedIDs itself, using the Agent SDS API.";
      };
      # Service name this ingress publishes for SRV discovery.
      service = mkOption { type = types.str; };
      # Callers ghostunnel (or the native application) accepts. The module
      # rejects an empty list, so access is always stated explicitly.
      allowedIDs = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      privateLoopback = mkOption {
        type = types.bool;
        default = false;
        description = "Reach a TCP backend through a socket-activated adapter in the workload namespace.";
      };
      hostLoopback = mkOption {
        type = types.bool;
        default = false;
        description = "Explicit host-loopback backend for a public edge or Internet gateway.";
      };
      backendUser = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Run this ingress as a dedicated local user to preserve Unix peer authentication.";
      };
    };
  };
  # Baseline sandbox for every unit this module creates. Proxy, adapter and
  # helper processes need no privileges, no writable system paths and only Unix
  # and IP sockets, so none of these settings has to be relaxed per workload.
  #
  # systemd does not mount PrivateTmp's tmpfs for a unit that joins another
  # unit's network namespace: the unit then keeps the host /tmp, which
  # ProtectSystem=strict has made read-only. An explicit tmpfs keeps /tmp
  # private and writable for every generated unit, including the ones that join
  # realm-net-<name>, and hides host /tmp contents from them. The mode matches
  # what PrivateTmp would use, because applications such as ncps write there as
  # an unprivileged user.
  privateTmp = "/tmp:mode=1777";
  # ghostunnel drains open connections on SIGTERM. An idle keep-alive peer holds
  # a connection until --max-conn-lifetime, so without this bound a restart waits
  # for systemd's stop timeout and is killed instead of exiting cleanly.
  drainTimeout = "15s";
  hardened = (import ../lib/proxy-hardening.nix) // {
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    PrivateTmp = true;
    TemporaryFileSystem = [ privateTmp ];
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateDevices = true;
    RestrictSUIDSGID = true;
    RestrictNamespaces = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    SystemCallArchitectures = "native";
    UMask = "0077";
    Restart = "on-failure";
    RestartSec = "3s";
  };
  # Socket ownership. The socket user accepts connections, the group names the
  # local peer allowed to connect, and mode 0660 lets exactly those two parties
  # through.
  activation = user: group: fd: {
    SocketUser = user;
    SocketGroup = group;
    SocketMode = "0660";
    RemoveOnStop = true;
    FileDescriptorName = fd;
  };
  workloadConfig =
    name: w:
    let
      netUnit = "realm-net-${name}.service";
      user = proxyUser name;
      egressSocket = route: e: if e.socket == null then egressPath name route else e.socket;
      # Shared settings for units that must live in the workload's loopback
      # namespace. bindsTo stops them with the namespace holder instead of
      # leaving them inside a torn-down private network.
      network = {
        requires = [ netUnit ];
        after = [ netUnit ];
        bindsTo = [ netUnit ];
        unitConfig.JoinsNamespaceOf = netUnit;
      };
    in
    lib.mkMerge (
      [
        {
          # Reject declarations that would deploy with weaker isolation than
          # they appear to request.
          assertions = [
            {
              assertion = builtins.match "[a-z][a-z0-9-]*" name != null && builtins.stringLength user < 32;
              message = "realm.workloads.${name}: use a short lowercase workload name.";
            }
            {
              assertion = w.user != "root" && w.group != "root";
              message = "realm.workloads.${name}: workloads must have an unprivileged user and group.";
            }
            {
              assertion = lib.hasPrefix "spiffe://${cfg.trustDomain}/" w.spiffeID;
              message = "realm.workloads.${name}: identity must belong to the configured trust domain.";
            }
            {
              assertion =
                builtins.length (lib.unique (map (i: i.port) (builtins.attrValues w.ingress)))
                == builtins.length (builtins.attrNames w.ingress);
              message = "realm.workloads.${name}: ingress ports must be unique.";
            }
            {
              assertion = w.runtime != "systemd" || (config.systemd.services.${appName w}.enable or false);
              message = "realm.workloads.${name}: the application unit must exist and be enabled.";
            }
          ];
          # Three identities: the application (<user>/<group>), one proxy
          # account per workload, and the shared realm-proxies group whose
          # members may read the SPIRE Agent socket.
          users.groups.${user} = { };
          users.groups.${w.group} = { };
          users.users.${w.user} = {
            isSystemUser = true;
            group = w.group;
          };
          users.users.${user} = {
            isSystemUser = true;
            group = user;
            extraGroups = [ "realm-proxies" ];
          };
          # egress is reachable by the application group, ingress only by the
          # proxy account, and both hold sockets rather than plain files.
          systemd.tmpfiles.rules = [
            "d ${base name} 0755 root root -"
            "d ${base name}/egress 0750 root ${w.group} -"
            "d ${base name}/ingress 0750 root ${user} -"
            # `d` sets ownership only when it creates the directory. A workload
            # whose group changes — a native gateway replacing the proxy account
            # it used to run as — would keep the old group, and the application
            # could no longer traverse the directory even though the sockets
            # inside are recreated with the new one. `z` re-applies the group to
            # the existing directory and, unlike `Z`, does not touch the sockets.
            "z ${base name}/egress 0750 root ${w.group} -"
            "z ${base name}/ingress 0750 root ${user} -"
          ];
          # Namespace holder. Socket units bind inside this namespace, so it
          # must exist before sockets.target and outlive every unit that joins
          # it. It runs nothing but sleep, and DefaultDependencies = false keeps
          # it out of the normal boot and shutdown ordering.
          systemd.services."realm-net-${name}" =
            mkIf (w.isolation.privateNetwork && (w.runtime == "systemd" || w.socksProxy.enable))
              {
                description = "Private loopback namespace for ${name}";
                wantedBy = [ "multi-user.target" ];
                before = [ "sockets.target" ];
                after = [ "systemd-tmpfiles-setup.service" ];
                unitConfig.DefaultDependencies = false;
                serviceConfig = {
                  ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
                  PrivateNetwork = true;
                  PrivateTmp = true;
                  DynamicUser = true;
                  NoNewPrivileges = true;
                  CapabilityBoundingSet = "";
                };
              };
          systemd.services.${appName w} = mkIf (w.runtime == "systemd") (
            lib.mkMerge [
              (lib.optionalAttrs w.isolation.privateNetwork network)
              {
                # The application keeps its private namespace and gets a
                # read-only /run, so the Agent socket stays invisible. Only the
                # paths listed below are mounted back.
                serviceConfig = {
                  PrivateNetwork = w.isolation.privateNetwork;
                  NoNewPrivileges = true;
                  CapabilityBoundingSet = lib.mkDefault "";
                  RestrictNamespaces = true;
                  PrivateTmp = true;
                  SystemCallArchitectures = "native";
                  RestrictAddressFamilies = [
                    "AF_UNIX"
                    "AF_INET"
                    "AF_INET6"
                  ];
                  # Hide host runtime sockets, then expose only declared capabilities.
                  TemporaryFileSystem = [
                    "/run:ro"
                    privateTmp
                  ];
                  BindReadOnlyPaths = [
                    "-/run/credentials/${w.unit}"
                    "-/run/systemd/notify"
                    "-/run/current-system"
                  ]
                  ++ lib.unique (lib.mapAttrsToList (route: e: builtins.dirOf (egressSocket route e)) w.egress)
                  ++ w.isolation.allowUnixSockets
                  # Aliases keep the original hostnames for SNI and certificate
                  # verification while the address points at a local adapter.
                  ++ lib.optional (w.isolation.hosts != { }) (
                    let
                      aliases = pkgs.writeText "realm-${name}-host-aliases" (
                        lib.concatStrings (lib.mapAttrsToList (host: address: "${address} ${host}\n") w.isolation.hosts)
                      );
                      hosts = pkgs.runCommand "realm-${name}-hosts" { } ''
                        # Remove inherited names that are overridden, including other address families.
                        awk '
                          NR == FNR {
                            for (i = 2; i <= NF; i++) replaced[tolower($i)] = 1
                            print
                            next
                          }
                          /^[[:space:]]*(#|$)/ { print; next }
                          {
                            line = $1; names = 0
                            for (i = 2; i <= NF && substr($i, 1, 1) != "#"; i++) {
                              if (!(tolower($i) in replaced)) { line = line " " $i; names++ }
                            }
                            if (names > 0) print line
                          }
                        ' ${aliases} ${config.environment.etc.hosts.source} > "$out"
                      '';
                    in
                    "${hosts}:/etc/hosts"
                  );
                  BindPaths = w.isolation.runtimePaths;
                };
              }
            ]
          );
        }
      ]
      ++ lib.mapAttrsToList (
        route: e:
        let
          unit = "realm-egress-${name}-${route}";
          candidates = destinations e.service;
          target =
            if e.target != null then
              e.target
            else if builtins.length candidates == 1 then
              builtins.head candidates
            else
              "[::1]:1";
        in
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = e.target != null || builtins.length candidates == 1;
                message = "${unit}: service ${e.service} must have exactly one catalog endpoint, or set an explicit target.";
              }
              {
                assertion = lib.hasPrefix "spiffe://" e.verifyID;
                message = "${unit}: verifyID must be an explicit SPIFFE ID.";
              }
              {
                assertion = e.localPort == null || w.isolation.privateNetwork;
                message = "${unit}: localPort requires a private namespace.";
              }
            ];
            # Registration of the egress proxy. Both selectors are required:
            # systemd creates the socket first and only then starts the proxy as
            # the workload's proxy account, and SPIRE must observe both facts.
            realm.spire.registrations.${unit} = {
              spiffeID = w.spiffeID;
              selectors = [
                "systemd:id:${unit}.service"
                "unix:user:${user}"
              ];
            };
            systemd.sockets.${unit} = {
              wantedBy = [ "sockets.target" ];
              listenStreams = [ (egressSocket route e) ];
              socketConfig = activation user w.group "egress";
            };
            systemd.services.${unit} = {
              requires = [ "spire-agent.service" ];
              after = [ "spire-agent.service" ];
              serviceConfig = hardened // {
                Type = "notify";
                NotifyAccess = "all";
                TimeoutStartSec = "90s";
                User = user;
                Group = user;
                SupplementaryGroups = [ "realm-proxies" ];
                # ghostunnel fetches the SVID and trust bundle from the Agent,
                # verifies the peer URI SAN and serves plaintext on the egress
                # socket. A one-hour connection lifetime bounds the effect of a
                # later policy change; certificate expiry alone closes nothing.
                ExecStart = lib.escapeShellArgs ([
                  "${cfg.ghostunnelPackage}/bin/ghostunnel"
                  "client"
                  "--use-workload-api"
                  "--cacert"
                  "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                  "--use-workload-api-addr"
                  "unix://${cfg.spire.socket}"
                  "--listen"
                  "systemd:egress"
                  "--verify-uri"
                  e.verifyID
                  "--max-conn-lifetime"
                  "1h"
                  "--shutdown-timeout"
                  drainTimeout
                  "--target"
                  target
                ]);
              };
            };
          }
          # Loopback adapter for clients that cannot use Unix sockets. It
          # exists only inside the workload namespace, so 127.0.0.1:<localPort>
          # is unreachable from the host and from other workloads.
          (mkIf
            (e.localPort != null && (w.runtime == "systemd" || (w.socksProxy.enable && route == "internet")))
            {
              systemd.sockets."realm-local-${name}-${route}" = network // {
                wantedBy = [ "sockets.target" ];
                listenStreams = [ "127.0.0.1:${toString e.localPort}" ];
                socketConfig = {
                  PrivateNetwork = true;
                };
              };
              systemd.services."realm-local-${name}-${route}" = network // {
                serviceConfig = hardened // {
                  User = user;
                  Group = user;
                  SupplementaryGroups = [ w.group ];
                  PrivateNetwork = true;
                  ExecStart = "${proxy} ${egressSocket route e}";
                };
              };
            }
          )
        ]
      ) w.egress
      ++ lib.mapAttrsToList (
        route: i:
        let
          unit = "realm-ingress-${name}-${route}";
          ingressUser = if i.backendUser == null then user else i.backendUser;
        in
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = i.allowedIDs != [ ];
                message = "${unit}: an explicit nonempty allowedIDs list is required.";
              }
              {
                assertion = !i.privateLoopback || w.isolation.privateNetwork;
                message = "${unit}: privateLoopback requires a private namespace.";
              }
              {
                assertion =
                  i.native
                  || (
                    i.target != null
                    && (
                      lib.hasPrefix "unix:" i.target
                      || i.privateLoopback
                      || (i.hostLoopback && lib.hasPrefix "127.0.0.1:" i.target)
                    )
                  );
                message = "${unit}: backend must be a Unix socket or an explicit loopback adapter.";
              }
              {
                assertion =
                  i.backendUser == null
                  || (
                    !i.native
                    && i.target != null
                    && i.backendUser != "root"
                    && builtins.length i.allowedIDs == 1
                    && lib.hasPrefix "unix:" i.target
                  );
                message = "${unit}: peer authentication requires an unprivileged user, exactly one authorized identity and a Unix backend.";
              }
              {
                assertion =
                  !i.native
                  || (
                    !w.isolation.privateNetwork
                    && w.runtime != "container"
                    && !i.privateLoopback
                    && !i.hostLoopback
                    && i.target == null
                    && i.backendUser == null
                    && (config.systemd.services.${appName w}.enable or false)
                  );
                message = "${unit}: native ingress requires a declared networked application unit and no proxy backend options.";
              }
            ];
            # Ingress registration. allowedIDs is the complete authorization
            # policy; publishing the port does not grant access by itself.
            realm.spire.registrations.${unit} = mkIf (!i.native) {
              spiffeID = w.spiffeID;
              selectors = [
                "systemd:id:${unit}.service"
                "unix:user:${ingressUser}"
              ];
            };
            realm.serviceDiscovery.publish.${i.service} = {
              unit = if i.native then w.unit else "${unit}.service";
              port = i.port;
            };
            systemd.sockets.${unit} = mkIf (!i.native) {
              wantedBy = [ "sockets.target" ];
              listenStreams = [ "[${cfg.address}]:${toString i.port}" ];
              socketConfig = {
                FileDescriptorName = "ingress";
                # Mesh addresses may be assigned after sockets.target during boot.
                FreeBind = true;
              };
            };
            systemd.services.${unit} = mkIf (!i.native) {
              wantedBy = [ "multi-user.target" ];
              requires = [
                "spire-agent.service"
                "${unit}.socket"
              ];
              after = [ "spire-agent.service" ];
              serviceConfig = hardened // {
                Type = "notify";
                TimeoutStartSec = "90s";
                User = ingressUser;
                Group = user;
                SupplementaryGroups = [ "realm-proxies" ] ++ w.ingressGroups;
                ExecStart = lib.escapeShellArgs (
                  [
                    "${cfg.ghostunnelPackage}/bin/ghostunnel"
                    "server"
                    "--use-workload-api"
                    "--cacert"
                    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                    "--use-workload-api-addr"
                    "unix://${cfg.spire.socket}"
                    "--listen"
                    "systemd:ingress"
                    "--target"
                    (if i.privateLoopback then "unix:${ingressPath name route}" else i.target)
                    "--max-conn-lifetime"
                    "1h"
                    "--shutdown-timeout"
                    drainTimeout
                  ]
                  ++ lib.concatMap (id: [
                    "--allow-uri"
                    id
                  ]) i.allowedIDs
                );
              };
            };
          }
          # Ingress-side adapter. The backend keeps listening on loopback inside
          # the workload namespace, so ghostunnel reaches it through this socket
          # and the backend never sees the mesh address.
          (mkIf i.privateLoopback {
            systemd.sockets."realm-backend-${name}-${route}" = {
              wantedBy = [ "sockets.target" ];
              listenStreams = [ (ingressPath name route) ];
              socketConfig = activation user user "backend";
            };
            systemd.services."realm-backend-${name}-${route}" = network // {
              requires = network.requires ++ [ w.unit ];
              after = network.after ++ [ w.unit ];
              serviceConfig = hardened // {
                User = user;
                Group = user;
                PrivateNetwork = true;
                ExecStart = "${proxy} ${proxyTarget i.target}";
              };
            };
          })
        ]
      ) w.ingress
      ++ [
        # gost turns the authenticated HTTP Internet egress into a SOCKS5
        # listener for applications that only speak SOCKS. UDP and BIND stay
        # disabled, so the adapter cannot be used as a general relay.
        (mkIf w.socksProxy.enable {
          assertions = [
            {
              assertion =
                w.isolation.privateNetwork
                && w.runtime != "external"
                && (w.egress ? internet)
                && w.egress.internet.localPort != null;
              message = "realm.workloads.${name}: SOCKS adaptation requires a private namespace and an internet egress with localPort.";
            }
          ];
          systemd.services."realm-socks-${name}" = network // {
            requires = network.requires ++ [ "realm-local-${name}-internet.socket" ];
            after = network.after ++ [ "realm-local-${name}-internet.socket" ];
            serviceConfig = hardened // {
              User = w.user;
              Group = w.group;
              PrivateNetwork = true;
              ExecStart = lib.escapeShellArgs [
                "${pkgs.gost}/bin/gost"
                "-L"
                "socks5://127.0.0.1:${toString w.socksProxy.port}?notls=true&bind=false&udp=false"
                "-F"
                "http://127.0.0.1:${toString w.egress.internet.localPort}"
              ];
              ExecStartPost = pkgs.writeShellScript "wait-realm-socks-${name}" ''
                for attempt in $(${pkgs.coreutils}/bin/seq 1 50); do
                  if ${pkgs.netcat-openbsd}/bin/nc -z -w 1 127.0.0.1 ${toString w.socksProxy.port}; then exit 0; fi
                  ${pkgs.coreutils}/bin/sleep 0.1
                done
                exit 1
              '';
            };
          };
          systemd.services.${appName w} = {
            requires = [ "realm-socks-${name}.service" ];
            after = [ "realm-socks-${name}.service" ];
          };
        })
        # A container cannot join the namespace listener, so it receives the
        # same SOCKS port over a mounted Unix socket instead.
        (mkIf (w.socksProxy.enable && w.runtime == "container") {
          systemd.sockets."realm-socks-unix-${name}" = {
            wantedBy = [ "sockets.target" ];
            listenStreams = [ "${base name}/egress/socks.sock" ];
            socketConfig = activation w.user w.group "socks";
          };
          systemd.services."realm-socks-unix-${name}" = network // {
            requires = network.requires ++ [ "realm-socks-${name}.service" ];
            after = network.after ++ [ "realm-socks-${name}.service" ];
            serviceConfig = hardened // {
              User = w.user;
              Group = w.group;
              PrivateNetwork = true;
              ExecStart = lib.escapeShellArgs [
                "${helper}/bin/realm-helper"
                "bridge"
                "--target"
                "127.0.0.1:${toString w.socksProxy.port}"
              ];
            };
          };
        })
        # Native ingress: the application terminates mTLS itself and consumes
        # SDS. The registration therefore attests the application unit and user,
        # and the application joins realm-proxies for Agent socket access.
        (mkIf (lib.any (i: i.native) (builtins.attrValues w.ingress)) {
          realm.spire.registrations."realm-native-${name}" = {
            spiffeID = w.spiffeID;
            selectors = [
              "systemd:id:${w.unit}"
              "unix:user:${w.user}"
            ];
          };
          systemd.services.${appName w} = {
            requires = [ "spire-agent.service" ];
            after = [ "spire-agent.service" ];
            serviceConfig.SupplementaryGroups = [ "realm-proxies" ];
          };
        })

      ]
    );
  # The fragments above are mkMerge trees that may contain mkIf nodes, but each
  # option below needs its own merge. `select` walks such a tree and projects one
  # option path out of it while preserving the conditions.
  generated = lib.mkMerge (lib.mapAttrsToList workloadConfig active);
  select =
    path: fallback: fragment:
    if fragment ? _type && fragment._type == "merge" then
      lib.mkMerge (map (select path fallback) fragment.contents)
    else if fragment ? _type && fragment._type == "if" then
      lib.mkIf fragment.condition (select path fallback fragment.content)
    else
      lib.attrByPath path fallback fragment;
in
{
  options.realm = {
    enable = lib.mkEnableOption "SPIFFE workload networking";
    # Identity namespace of every SVID. The discovery DNS domain is separate.
    trustDomain = mkOption {
      type = types.str;
      default = "nyaw.xyz";
    };
    # The only place a SPIFFE ID string is assembled. Every other module
    # composes IDs from these prefixes, so the trust domain appears once and a
    # renamed identity is a one-line change instead of a repository-wide grep.
    servicePrefix = mkOption {
      type = types.str;
      readOnly = true;
      default = "spiffe://${cfg.trustDomain}/service/";
    };
    # Address ingress sockets bind to, normally the node's mesh IPv6 address.
    address = mkOption {
      type = types.str;
      default = config.realm.serviceDiscovery.address;
    };
    ghostunnelPackage = lib.mkPackageOption pkgs "ghostunnel" { };
    # Static helper for the per-workload and per-node jobs that are too small to
    # justify their own binary: socket bridges, the
    # container entrypoint adapters and the SPIRE registration reconciler.
    helperPackage = mkOption {
      type = types.package;
      default = pkgs.callPackage ../pkgs/realm-helper { };
      defaultText = lib.literalExpression "pkgs.callPackage ../pkgs/realm-helper { }";
      description = "Binary implementing the per-namespace helper subcommands.";
    };
    # One entry per service that must talk to, or be reached by, the mesh.
    workloads = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
              };
              # Application unit whose sandbox and dependencies are configured.
              unit = mkOption {
                type = types.strMatching ".+\\.service";
                default = "${name}.service";
              };
              # Account the application itself runs as.
              user = mkOption {
                type = types.str;
                default = name;
              };
              group = mkOption {
                type = types.str;
                default = name;
              };
              # systemd:    the module builds the sandbox, sockets and adapters.
              # container:  the container engine mounts the egress sockets.
              # external:   only DNS, registrations and egress helpers are
              #             generated; the application is wired elsewhere.
              runtime = mkOption {
                type = types.enum [
                  "systemd"
                  "container"
                  "external"
                ];
                default = "systemd";
              };
              # Identity shared by every process of this workload; declaring the
              # same ID twice merges their authorization.
              spiffeID = mkOption {
                type = types.str;
                default = "${cfg.servicePrefix}${name}";
              };
              isolation = {
                # Remove the route to the host and the Internet. Disable it only
                # for an edge or gateway role that must accept public traffic.
                privateNetwork = mkOption {
                  type = types.bool;
                  default = true;
                };
                # Additional host runtime paths the application may use, e.g.
                # journal sockets for log collection.
                allowUnixSockets = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                hosts = mkOption {
                  type = types.attrsOf types.str;
                  default = { };
                  description = "Workload-local host aliases, preserving TLS names when dialing private egress adapters.";
                };
                runtimePaths = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
              # Extra groups allowed to connect to this workload's ingress
              # sockets; the proxy group is always included.
              ingressGroups = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              egress = mkOption {
                type = types.attrsOf endpointType;
                default = { };
              };
              ingress = mkOption {
                type = types.attrsOf ingressType;
                default = { };
              };
              # SOCKS5 adapter for clients that cannot use an HTTP proxy.
              socksProxy = {
                enable = lib.mkEnableOption "a local SOCKS5 adapter through the authenticated HTTP Internet egress";
                port = mkOption {
                  type = types.port;
                  default = 11080;
                };
              };
            };
          }
        )
      );
    };
  };
  config = mkIf cfg.enable {
    # realm-proxies is the group that may read the SPIRE Agent socket; only
    # proxy, adapter and helper accounts are members.
    users.groups = lib.mkMerge [
      { realm-proxies = { }; }
      (select [ "users" "groups" ] { } generated)
    ];
    users.users = select [ "users" "users" ] { } generated;
    systemd.services = select [ "systemd" "services" ] { } generated;
    systemd.sockets = select [ "systemd" "sockets" ] { } generated;
    systemd.tmpfiles.rules = select [ "systemd" "tmpfiles" "rules" ] [ ] generated;
    realm.spire.registrations = select [ "realm" "spire" "registrations" ] { } generated;
    realm.serviceDiscovery.publish = select [ "realm" "serviceDiscovery" "publish" ] { } generated;
    assertions = lib.mkMerge [
      (select [ "assertions" ] [ ] generated)
      [
        {
          assertion = config.realm.serviceDiscovery.enable;
          message = "realm: CoreDNS service discovery must be enabled.";
        }
      ]
    ];
  };
}
