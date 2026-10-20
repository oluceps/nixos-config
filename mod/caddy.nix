{
  flake.modules.nixos.caddy =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf;
      cfg = config.caddy;
      format = pkgs.formats.json { };
      configfile = format.generate "config.json" cfg.settings;
    in
    {

      options = {
        caddy = {
          # moved to upper module
          # enable = lib.mkEnableOption "caddy api gateway";
          # mkPackageOption not work here
          expose = lib.mkEnableOption "API env";
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.caddy-realm;
            # ;
          };
          settings = lib.mkOption {
            type = lib.types.submodule { freeformType = format.type; };
            default = { };
          };
        };
      };

      config = {
        users.groups.caddy = { };
        users.users.caddy = {
          isSystemUser = true;
          group = "caddy";
        };
        realm.workloads.caddy = {
          runtime = "external";
          isolation.privateNetwork = false;
          egress = {
            atuin = {
              service = "atuin";
              verifyID = "spiffe://nyaw.xyz/service/atuin";
            };
          };
        };
        realm.discovery.integrateCaddy = true;
        caddy.settings.apps.layer4.servers = mkIf config.realm.enable config.realm.discovery.servers;
        realm.observability.endpoints.caddy.port = 20242;
        caddy.settings.apps.http.servers.observability = {
          listen = [ "127.0.0.1:20242" ];
          automatic_https.disable = true;
          routes = [ { handle = [ { handler = "metrics"; } ]; } ];
        };
        vaultix.secrets.caddy = { };
        networking.firewall = lib.mkIf (!config.data.node.${config.networking.hostName}.nat) {
          allowedTCPPorts = [
            80
            443
          ];
          allowedUDPPorts = [ 443 ];
        };
        caddy.settings = {
          admin = {
            config.persist = false;
          };
          # logging.logs.debug.level = "debug";
          storage = mkIf cfg.expose {
            module = "s3";
            prefix = "ssl";
            insecure = false;
          };
          apps = {
            http.metrics = { };
            http.grace_period = "1s";
            http.servers.srv0 = {
              listen = [ ":443" ];
              strict_sni_host = false;
              automatic_https = {
                skip_certificates = [
                ];
              };

            };

          };
        };

        environment.etc."caddy/config.json".source = configfile;
        environment.systemPackages = [ cfg.package ];

        systemd.services.caddy = {
          preStart = "cp -f /etc/caddy/config.json /var/lib/caddy/backup.json";
          unitConfig = {
            StartLimitIntervalSec = 0;
          };
          serviceConfig =
            let
              caddyBin = "${cfg.package}/bin/caddy";
            in
            {
              Type = "notify";
              ExecStartPre = "${caddyBin} validate --config /etc/caddy/config.json";
              ExecStart = "${caddyBin} run --config /etc/caddy/config.json";
              ExecReload = "${caddyBin} reload --force --config /etc/caddy/config.json";
              DynamicUser = true;
              StateDirectory = "caddy";
              ReadWritePaths = lib.optionals (config.realm.enable && config.realm.discovery.servers != { }) [
                "/run/realm-discovery"
              ];
              AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
              Environment = [ "XDG_DATA_HOME=%S" ];
              Restart = "always";
              EnvironmentFile = mkIf cfg.expose config.vaultix.secrets.caddy.path;
              LoadCredential = mkIf (!cfg.expose) (
                (map (config.fn.genCredPath)) [
                  "nyaw.cert"
                  "nyaw.key"
                ]
              );
              RestartSec = 1;
            };
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "network-online.target"
            "systemd-tmpfiles-setup.service"
            "consul.service"
          ];
          wants = [ "consul.service" ];
          requires = [ "network-online.target" ];
          reloadTriggers = [ configfile ];
        };
      };
    };
}
