{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.realm;
  active = lib.filterAttrs (_: w: w.enable) cfg.workloads;
  python = pkgs.python3.withPackages (p: [ p.dnspython ]);
  proxy = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd";
  appName = w: lib.removeSuffix ".service" w.unit;
  proxyUser = name: "realm-${name}";
  base = name: "/run/realm/${name}";
  egressPath = name: route: "${base name}/egress/${route}.sock";
  ingressPath = name: route: "${base name}/ingress/${route}.sock";
  endpointType = types.submodule (
    { name, ... }:
    {
      options = {
        service = mkOption { type = types.str; };
        verifyID = mkOption { type = types.str; };
        target = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Fixed TLS destination as host:port, instead of SRV discovery.";
        };
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
      port = mkOption { type = types.port; };
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      native = mkOption {
        type = types.bool;
        default = false;
        description = "The application terminates SPIFFE mTLS and enforces allowedIDs itself, using the Agent SDS API.";
      };
      consulService = mkOption { type = types.str; };
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
  hardened = {
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    PrivateTmp = true;
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
          systemd.tmpfiles.rules = [
            "d ${base name} 0755 root root -"
            "d ${base name}/egress 0750 root ${w.group} -"
            "d ${base name}/ingress 0750 root ${user} -"
          ];
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
                  TemporaryFileSystem = [ "/run:ro" ];
                  BindReadOnlyPaths = [
                    "-/run/credentials/${w.unit}"
                    "-/run/systemd/notify"
                    "-/run/current-system"
                  ]
                  ++ lib.unique (
                    lib.mapAttrsToList (route: e: builtins.dirOf (egressSocket route e)) w.egress
                    ++ lib.optional w.isolation.dns "${base name}/egress"
                  )
                  ++ lib.optional w.isolation.dns "${pkgs.writeText "realm-resolv.conf" "nameserver 127.0.0.53\noptions edns0 trust-ad\n"}:/etc/resolv.conf"
                  ++ w.isolation.allowUnixSockets
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
        in
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = lib.hasPrefix "spiffe://" e.verifyID;
                message = "${unit}: verifyID must be an explicit SPIFFE ID.";
              }
              {
                assertion = e.localPort == null || w.isolation.privateNetwork;
                message = "${unit}: localPort requires a private namespace.";
              }
            ];
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
                ExecStart = lib.escapeShellArgs (
                  lib.optionals (e.target == null) [
                    "${python}/bin/python3"
                    "${./realm/srv-egress.py}"
                    "--service"
                    "${e.service}.service.${cfg.discovery.domain}"
                    "--resolver"
                    cfg.discovery.resolver
                    "--resolver-port"
                    (toString cfg.discovery.port)
                    "--"
                  ]
                  ++ [
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
                  ]
                  ++ lib.optionals (e.target != null) [
                    "--target"
                    e.target
                  ]
                );
              };
            };
          }
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
            realm.spire.registrations.${unit} = mkIf (!i.native) {
              spiffeID = w.spiffeID;
              selectors = [
                "systemd:id:${unit}.service"
                "unix:user:${ingressUser}"
              ];
            };
            realm.serviceDiscovery.publish.${i.consulService} = {
              unit = if i.native then w.unit else "${unit}.service";
              port = i.port;
              checks = lib.optionals (!i.native) [
                {
                  id = "${config.networking.hostName}-${i.consulService}-backend";
                  name = "${w.unit} is active";
                  args = [
                    "${config.systemd.package}/bin/systemctl"
                    "is-active"
                    "--quiet"
                    w.unit
                  ];
                  interval = "10s";
                  timeout = "2s";
                }
              ];
            };
            systemd.sockets.${unit} = mkIf (!i.native) {
              wantedBy = [ "sockets.target" ];
              listenStreams = [ "[${cfg.address}]:${toString i.port}" ];
              socketConfig.FileDescriptorName = "ingress";
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
                  ]
                  ++ lib.concatMap (id: [
                    "--allow-uri"
                    id
                  ]) i.allowedIDs
                );
              };
            };
          }
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
                ExecStart = "${proxy} ${i.target}";
              };
            };
          })
        ]
      ) w.ingress
      ++ [
        (mkIf w.isolation.dns {
          assertions = [
            {
              assertion = w.runtime == "systemd" && w.isolation.privateNetwork && !(w.egress ? dns);
              message = "realm.workloads.${name}: local DNS requires a private systemd workload and reserves egress/dns.sock.";
            }
          ];
          # DNS infrastructure remains host-local. Only this fixed resolver is reachable.
          systemd.sockets."realm-dns-egress-${name}" = {
            wantedBy = [ "sockets.target" ];
            listenStreams = [ "${base name}/egress/dns.sock" ];
            socketConfig = activation user w.group "dns";
          };
          systemd.services."realm-dns-egress-${name}".serviceConfig = hardened // {
            User = user;
            Group = user;
            IPAddressDeny = "any";
            IPAddressAllow = "localhost";
            ExecStart = "${proxy} 127.0.0.53:53";
          };
          systemd.sockets."realm-dns-udp-${name}" = network // {
            wantedBy = [ "sockets.target" ];
            listenDatagrams = [ "127.0.0.53:53" ];
            socketConfig.PrivateNetwork = true;
          };
          systemd.services."realm-dns-udp-${name}" = network // {
            requires = network.requires ++ [ "realm-dns-egress-${name}.socket" ];
            after = network.after ++ [ "realm-dns-egress-${name}.socket" ];
            serviceConfig = hardened // {
              User = user;
              Group = user;
              SupplementaryGroups = [ w.group ];
              PrivateNetwork = true;
              ExecStart = "${python}/bin/python3 ${./realm/dns-udp.py} ${base name}/egress/dns.sock";
            };
          };
          systemd.sockets."realm-dns-tcp-${name}" = network // {
            wantedBy = [ "sockets.target" ];
            listenStreams = [ "127.0.0.53:53" ];
            socketConfig.PrivateNetwork = true;
          };
          systemd.services."realm-dns-tcp-${name}" = network // {
            requires = network.requires ++ [ "realm-dns-egress-${name}.socket" ];
            after = network.after ++ [ "realm-dns-egress-${name}.socket" ];
            serviceConfig = hardened // {
              User = user;
              Group = user;
              SupplementaryGroups = [ w.group ];
              PrivateNetwork = true;
              ExecStart = "${proxy} ${base name}/egress/dns.sock";
            };
          };
        })
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
              ExecStart = "${proxy} 127.0.0.1:${toString w.socksProxy.port}";
            };
          };
        })
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
        (mkIf w.credentials.enable {
          realm.spire.registrations."realm-helper-${name}" = {
            spiffeID = w.spiffeID;
            selectors = [
              "systemd:id:realm-helper-${name}.service"
              "unix:user:${user}"
            ];
          };
          systemd.tmpfiles.rules = [ "d ${w.credentials.directory} 0750 ${user} ${w.group} -" ];
          systemd.services."realm-helper-${name}" = {
            wantedBy = [ "multi-user.target" ];
            requires = [ "spire-agent.service" ];
            after = [ "spire-agent.service" ];
            serviceConfig = hardened // {
              User = user;
              Group = w.group;
              SupplementaryGroups = [ "realm-proxies" ];
              UMask = "0027";
              ReadWritePaths = [ w.credentials.directory ];
              ExecStartPost = pkgs.writeShellScript "wait-realm-helper-${name}" ''
                for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
                  if ${pkgs.openssl}/bin/openssl x509 -in ${lib.escapeShellArg "${w.credentials.directory}/svid.pem"} -noout -checkend 0 >/dev/null 2>&1 && test -s ${lib.escapeShellArg "${w.credentials.directory}/key.pem"}; then
                    exit 0
                  fi
                  ${pkgs.coreutils}/bin/sleep 1
                done
                exit 1
              '';
              ExecStart = "${pkgs.spiffe-helper}/bin/spiffe-helper -config ${
                (pkgs.formats.hcl1 { }).generate "realm-helper-${name}.conf" (
                  {
                    agent_address = cfg.spire.socket;
                    cert_dir = w.credentials.directory;
                    svid_file_name = "svid.pem";
                    svid_key_file_name = "key.pem";
                    svid_bundle_file_name = "bundle.pem";
                    daemon_mode = true;
                    key_file_mode = 416;
                  }
                  // w.credentials.settings
                )
              }";
            };
          };
          systemd.services.${appName w} = {
            requires = [ "realm-helper-${name}.service" ];
            after = [ "realm-helper-${name}.service" ];
            serviceConfig.BindReadOnlyPaths = [ w.credentials.directory ];
          };
        })
      ]
    );
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
    trustDomain = mkOption {
      type = types.str;
      default = "nyaw.xyz";
    };
    address = mkOption {
      type = types.str;
      default = config.realm.serviceDiscovery.address;
    };
    ghostunnelPackage = lib.mkPackageOption pkgs "ghostunnel" { };
    discovery = {
      domain = mkOption {
        type = types.str;
        default = "mesh.nyaw.xyz";
      };
      resolver = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };
      port = mkOption {
        type = types.port;
        default = 8600;
      };
    };
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
              unit = mkOption {
                type = types.strMatching ".+\\.service";
                default = "${name}.service";
              };
              user = mkOption {
                type = types.str;
                default = name;
              };
              group = mkOption {
                type = types.str;
                default = name;
              };
              runtime = mkOption {
                type = types.enum [
                  "systemd"
                  "container"
                  "external"
                ];
                default = "systemd";
              };
              spiffeID = mkOption {
                type = types.str;
                default = "spiffe://${cfg.trustDomain}/service/${name}";
              };
              isolation = {
                dns = lib.mkEnableOption "a private DNS stub through a Unix socket to the existing host resolver";
                privateNetwork = mkOption {
                  type = types.bool;
                  default = true;
                };
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
              credentials = {
                enable = lib.mkEnableOption "spiffe-helper for an explicitly configured native SPIFFE TLS consumer";
                directory = mkOption {
                  type = types.str;
                  default = "/run/realm/${name}/credentials";
                };
                settings = mkOption {
                  type = (pkgs.formats.hcl1 { }).type;
                  default = { };
                };
              };
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
          message = "realm: Consul service discovery must be enabled.";
        }
      ]
    ];
  };
}
