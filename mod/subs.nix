{
  flake.modules.nixos.subs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.subs.scriptPath = lib.mkOption {
        type = lib.types.str;
        default = config.vaultix.secrets.subs.path;
      };
      config = {
        realm.workloads.subs = {
          ingress.http = {
            port = 18004;
            target = "[::1]:8004";
            privateLoopback = true;
            service = "subs";
            allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
          };
          egress.internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/internet";
            localPort = 13128;
          };
        };
        realm.workloads.caddy = lib.mkIf (config ? caddy) {
          egress.subs = {
            service = "subs";
            verifyID = "spiffe://nyaw.xyz/service/subs";
          };
        };
        systemd.services.subs = {
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig.Type = "simple";
          serviceConfig = {
            User = "subs";
            Group = "subs";
            StateDirectory = "subs";
            WorkingDirectory = "/var/lib/subs";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateDevices = true;
            LoadCredential = [ "main.ts:${config.subs.scriptPath}" ];
          };
          serviceConfig.ExecStart = "${lib.getExe pkgs.deno} run --allow-env --allow-net --no-check \${CREDENTIALS_DIRECTORY}/main.ts";
          environment = {
            DENO_DIR = "/var/lib/subs/deno";
            HTTP_PROXY = "http://127.0.0.1:13128";
            HTTPS_PROXY = "http://127.0.0.1:13128";
            NO_PROXY = "localhost,127.0.0.1,::1";
          };
          serviceConfig.Restart = "always";
          serviceConfig.RestartSec = 1;
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
        };
      };
    };
}
