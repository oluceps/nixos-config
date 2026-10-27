{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.realm;
  active = lib.filterAttrs (_: w: cfg.enable && w.enable && w.transparent.enable) cfg.workloads;
  directory = name: "/run/realm-agent/${name}";
  control = name: "${directory name}/control.sock";
  workerUser = name: "rnet-${name}";
  socketFor =
    name: route:
    let
      e = cfg.workloads.${name}.egress.${route} or null;
    in
    if e == null then
      "/missing-egress"
    else if e.socket != null then
      e.socket
    else
      "/run/realm/${name}/egress/${route}.sock";
  generated = pkgs.writeText "realm-agent.json" (
    builtins.toJSON {
      namespaceTool = "${pkgs.util-linux}/bin/nsenter";
      networkTool = "${pkgs.iproute2}/bin/ip";
      workloads = lib.mapAttrsToList (name: w: {
        inherit name;
        user = w.user;
        group = w.group;
        workerUser = workerUser name;
        socket = control name;
        internetSocket =
          if w.transparent.internetRoute == null then "" else socketFor name w.transparent.internetRoute;
        inherit (w.transparent)
          internetPorts
          dnsUpstream
          tcpPort
          dnsBase
          maxConnections
          ;
        dnsHosts = lib.mapAttrs (_: address: [ address ]) w.isolation.hosts // w.transparent.dnsHosts;
        routes = map (r: {
          inherit (r) prefix port;
          socket = socketFor name r.egress;
        }) w.transparent.routes;
      }) active;
    }
  );
in
{
  imports = [
    ./realm-workloads.nix
    ./realm-container.nix
  ];
  options.realm = {
    agent.package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../pkgs/realm-agent { };
      description = "Static Realm host agent with its embedded BPF programs.";
    };
    workloads = mkOption {
      type = types.attrsOf (
        types.submodule {
          options.transparent = {
            enable = lib.mkEnableOption "cgroup BPF capture inside this workload's namespace without external links";
            internetRoute = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Declared HTTP CONNECT egress; null disables public Internet and external DNS.";
            };
            internetPorts = mkOption {
              type = types.listOf types.port;
              default = [ 443 ];
              description = "Public TCP ports; the remote gateway must independently authorize CONNECT to them.";
            };
            dnsUpstream = mkOption {
              type = types.str;
              default = "https://cloudflare-dns.com/dns-query";
            };
            dnsHosts = mkOption {
              type = types.attrsOf (types.listOf types.str);
              default = { };
              description = "Workload-local authoritative DNS overrides, merged with isolation.hosts.";
            };
            tcpPort = mkOption {
              type = types.port;
              default = 15001;
            };
            dnsBase = mkOption {
              type = types.port;
              default = 15053;
              description = "First of eight UDP DNS adapter ports in each address family.";
            };
            maxConnections = mkOption {
              type = types.ints.between 1 4096;
              default = 256;
            };
            routes = mkOption {
              default = [ ];
              type = types.listOf (
                types.submodule {
                  options = {
                    prefix = mkOption {
                      type = types.str;
                      description = "Destination IP prefix selected by this route.";
                    };
                    port = mkOption { type = types.port; };
                    egress = mkOption {
                      type = types.str;
                      description = "Name of an existing workload egress.";
                    };
                  };
                }
              );
            };
          };
        }
      );
    };
  };
  config = lib.mkIf (active != { }) {
    boot.kernelModules = [ "dummy" ];
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: w: [
        {
          assertion =
            builtins.elem w.runtime [
              "systemd"
              "container"
            ]
            && w.isolation.privateNetwork;
          message = "realm.workloads.${name}.transparent requires an isolated systemd or container workload.";
        }
        {
          assertion = builtins.stringLength (workerUser name) < 32;
          message = "realm.workloads.${name}.transparent: worker user name is too long.";
        }
        {
          assertion =
            w.runtime != "systemd"
            || (
              let
                unit = lib.removeSuffix ".service" w.unit;
                service = config.systemd.services.${unit}.serviceConfig;
                # DynamicUser defaults User to the unit name. Realm declares
                # that account statically, so the attested UID remains stable.
                configuredUser = service.User or "";
                user =
                  if configuredUser != "" then
                    configuredUser
                  else if service.DynamicUser or false then
                    unit
                  else
                    "";
              in
              user == w.user
            );
          message = "realm.workloads.${name}.transparent: the application unit must run as its configured workload user.";
        }
        {
          assertion =
            w.transparent.internetRoute == null || builtins.hasAttr w.transparent.internetRoute w.egress;
          message = "realm.workloads.${name}.transparent.internetRoute must name a declared egress.";
        }
        {
          assertion = lib.all (r: builtins.hasAttr r.egress w.egress) w.transparent.routes;
          message = "realm.workloads.${name}.transparent.routes must refer to declared egresses.";
        }
        {
          assertion =
            w.runtime != "container"
            || (
              config.virtualisation.oci-containers.containers.${w.container.name}.networks == [ "none" ]
              && config.virtualisation.oci-containers.containers.${w.container.name}.podman.user == w.user
            );
          message = "realm.workloads.${name}.transparent: containers require network=none and the configured workload user.";
        }
        {
          assertion =
            w.transparent.dnsBase <= 65528
            && !(
              w.transparent.tcpPort >= w.transparent.dnsBase && w.transparent.tcpPort < w.transparent.dnsBase + 8
            )
            && lib.all (
              e:
              e.localPort == null
              || (
                e.localPort != w.transparent.tcpPort
                && !(e.localPort >= w.transparent.dnsBase && e.localPort < w.transparent.dnsBase + 8)
              )
            ) (builtins.attrValues w.egress);
          message = "realm.workloads.${name}.transparent: adapter ports overlap another route.";
        }
      ]) active
    );
    users.users = lib.mapAttrs' (
      name: w:
      lib.nameValuePair (workerUser name) {
        isSystemUser = true;
        group = w.group;
      }
    ) active;
    systemd.tmpfiles.rules = [
      "d /run/realm-agent 0755 root root -"
    ]
    ++ lib.mapAttrsToList (name: w: "d ${directory name} 0750 root ${w.group} -") active;
    systemd.services = {
      realm-agent = {
        description = "Realm cgroup BPF host agent";
        wantedBy = [ "multi-user.target" ];
        after = [
          "systemd-tmpfiles-setup.service"
          "userborn.service"
        ];
        restartTriggers = [ generated ];
        serviceConfig = {
          Type = "notify";
          NotifyAccess = "main";
          ExecStartPre = "${cfg.agent.package}/bin/realm-agent validate --config ${generated}";
          ExecStart = "${cfg.agent.package}/bin/realm-agent serve --config ${generated}";
          Restart = "on-failure";
          RestartSec = "2s";
          TimeoutStartSec = "60s";
          TimeoutStopSec = "15s";
          KillMode = "control-group";
          UMask = "0077";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectControlGroups = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectKernelLogs = true;
          PrivateTmp = true;
          ReadWritePaths = [ "/run/realm-agent" ];
          RestrictNamespaces = [ "net" ];
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          CapabilityBoundingSet = [
            "CAP_BPF"
            "CAP_NET_ADMIN"
            "CAP_SYS_ADMIN"
            "CAP_SYS_PTRACE"
            "CAP_SETUID"
            "CAP_SETGID"
            "CAP_CHOWN"
            "CAP_DAC_OVERRIDE"
            "CAP_DAC_READ_SEARCH"
            "CAP_FOWNER"
          ];
          LimitMEMLOCK = "infinity";
          MemoryMax = "512M";
          TasksMax = 1024;
        };
      };
    }
    // lib.mapAttrs' (
      name: w:
      lib.nameValuePair (lib.removeSuffix ".service" w.unit) (
        {
          # The readiness gate enforces startup. Requires would propagate the
          # agent's automatic restart to otherwise recoverable applications.
          wants = [ "realm-agent.service" ];
          after = [ "realm-agent.service" ];
        }
        // lib.optionalAttrs (w.runtime == "systemd") {
          serviceConfig = {
            ExecStartPre = lib.mkBefore [
              "${cfg.agent.package}/bin/realm-agent gate --socket ${control name}"
            ];
            BindReadOnlyPaths = [ (directory name) ];
          };
        }
      )
    ) active;
    virtualisation.oci-containers.containers = lib.mapAttrs' (
      name: w:
      lib.nameValuePair w.container.name {
        volumes = [ "${directory name}:/realm/agent:ro" ];
        environment.REALM_AGENT_SOCKET = "/realm/agent/control.sock";
      }
    ) (lib.filterAttrs (_: w: w.runtime == "container") active);
  };
}
