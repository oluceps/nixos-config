{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.realm;
  scfg = cfg.spire;
  spire = pkgs.spire;
  adminSocket = "/run/spire/server/private/api.sock";
  manifest = pkgs.writeText "realm-spire-registrations.json" (
    builtins.toJSON scfg.server.registrations
  );
  enroll = pkgs.writeScriptBin "realm-enroll" ''
    #!${pkgs.python3}/bin/python3
    import json, subprocess, sys
    nodes = json.load(open(${builtins.toJSON (toString manifest)}))
    if len(sys.argv) != 2 or sys.argv[1] not in nodes:
        sys.exit("usage: realm-enroll NODE (configured mesh node)")
    node = sys.argv[1]
    token = json.loads(subprocess.check_output([
        "${spire}/bin/spire-server", "token", "generate", "-socketPath", "${adminSocket}",
        "-spiffeID", "spiffe://${cfg.trustDomain}/agent/" + node,
        "-ttl", "600", "-output", "json"
    ]))
    bundle = subprocess.check_output([
        "${spire}/bin/spire-server", "bundle", "show", "-socketPath", "${adminSocket}"
    ], text=True)
    print(json.dumps({"node": node, "token": token["value"], "bundle": bundle}))
  '';
  installEnrollment = pkgs.writeScriptBin "realm-install-enrollment" ''
    #!${pkgs.python3}/bin/python3
    import json, os, pathlib, subprocess, sys
    if os.geteuid() != 0:
        sys.exit("must run as root")
    data = json.load(sys.stdin)
    if data["node"] != ${builtins.toJSON config.networking.hostName}:
        sys.exit("enrollment is for a different node")
    root = pathlib.Path("/var/lib/realm-spire")
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(root, 0o700)
    for name, value in [("join-token", data["token"]), ("trust-bundle.pem", data["bundle"])]:
        path = root / name
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, "w") as stream:
            stream.write(value)
    subprocess.run(["${config.systemd.package}/bin/systemctl", "restart", "spire-agent.service"], check=True)
  '';
in
{
  options.realm.spire = {
    socket = lib.mkOption {
      type = lib.types.str;
      default = "/run/spire/agent/public/api.sock";
    };
    serverAddress = lib.mkOption {
      type = lib.types.str;
      default = "eihort.node.mesh.nyaw.xyz";
    };
    registrations = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            spiffeID = lib.mkOption { type = lib.types.str; };
            selectors = lib.mkOption { type = lib.types.listOf lib.types.str; };
          };
        }
      );
      default = { };
      description = "Public registration declarations for the local workload proxies and helpers.";
    };
    server = {
      enable = lib.mkEnableOption "SPIRE control plane on this node";
      registrations = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.attrs);
        default = { };
      };
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.spire.agent = {
          enable = true;
          settings = {
            agent = {
              trust_domain = cfg.trustDomain;
              server_address = scfg.serverAddress;
              socket_path = scfg.socket;
              join_token_file = "/var/lib/realm-spire/join-token";
              trust_bundle_path = "/var/lib/realm-spire/trust-bundle.pem";
            };
            plugins = {
              KeyManager.disk.plugin_data.directory = "$STATE_DIRECTORY/keys";
              NodeAttestor.join_token.plugin_data = { };
              WorkloadAttestor.systemd.plugin_data = { };
              WorkloadAttestor.unix.plugin_data = { };
            };
          };
        };
        systemd.services.spire-agent = {
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          unitConfig.ConditionPathExists = "/var/lib/realm-spire/trust-bundle.pem";
          serviceConfig = {
            User = lib.mkForce "root";
            Group = lib.mkForce "realm-proxies";
            UMask = lib.mkForce "0007";
            RuntimeDirectoryMode = "0750";
            RestartSec = "5s";
            ExecStartPost = pkgs.writeShellScript "wait-spire-agent" ''
              for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
                if ${spire}/bin/spire-agent healthcheck -socketPath ${lib.escapeShellArg scfg.socket} >/dev/null 2>&1; then
                  exit 0
                fi
                ${pkgs.coreutils}/bin/sleep 1
              done
              exit 1
            '';
          };
        };
        environment.systemPackages = [ installEnrollment ];
      }
      (lib.mkIf scfg.server.enable {
        services.spire.server = {
          enable = true;
          settings = {
            server = {
              trust_domain = cfg.trustDomain;
              bind_address = cfg.address;
              default_x509_svid_ttl = "1h";
            };
            plugins = {
              KeyManager.disk.plugin_data.keys_path = "$STATE_DIRECTORY/keys.json";
              DataStore.sql.plugin_data = {
                database_type = "sqlite3";
                connection_string = "$STATE_DIRECTORY/datastore.sqlite3";
              };
              NodeAttestor.join_token.plugin_data = { };
            };
          };
        };
        systemd.services.spire-server = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig.RestartSec = "5s";
        };
        environment.systemPackages = [ enroll ];
        systemd.services.realm-spire-register = {
          description = "Reconcile declarative SPIRE workload registrations";
          wantedBy = [ "multi-user.target" ];
          requires = [ "spire-server.service" ];
          after = [ "spire-server.service" ];
          restartTriggers = [ manifest ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            StateDirectory = "realm-spire-registrations";
            StateDirectoryMode = "0700";
            ExecStart = lib.escapeShellArgs [
              "${pkgs.python3}/bin/python3"
              "${./realm/spire-register.py}"
              "${spire}/bin/spire-server"
              adminSocket
              manifest
              "/var/lib/realm-spire-registrations/entries.json"
            ];
          };
        };
      })
    ]
  );
}
