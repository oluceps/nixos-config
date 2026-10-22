{
  flake.modules.nixos.vaultwarden =
    { config, pkgs, ... }:
    {
      vaultix.secrets.vault = { };
      realm.workloads.vaultwarden = {
        http = {
          internet = true;
          internal = [ "oidc.nyaw.xyz" ];
        };
        isolation.hosts."box.nyaw.xyz" = "127.0.0.1";
        ingress.http = {
          port = 18003;
          target = "127.0.0.1:8003";
          privateLoopback = true;
          service = "vaultwarden";
          allowedIDs = config.realm.caddy.allowedIDs.vaultwarden;
        };
        egress = {
          smtp = {
            service = "smtp-submission";
            verifyID = "spiffe://nyaw.xyz/service/stalwart";
            localPort = 465;
          };
        };
      };
      systemd.services.vaultwarden = {
        after = [ "postgresql.target" ];
        requires = [ "postgresql.target" ];
        serviceConfig.BindReadOnlyPaths = [ "/run/postgresql" ];
      };
      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        config = {
          signupsAllowed = false;
          sendsAllowed = true;
          emergencyAccessAllowed = false;
          orgCreationUsers = "none";
          domain = "https://vault.nyaw.xyz";
          rocketAddress = "127.0.0.1";
          rocketPort = 8003;
        };
        # backupDir = "/var/lib/bitwarden_rs/backup";
        environmentFile = [
          config.vaultix.secrets.vault.path
          # This file overrides the database URL from the encrypted environment.
          (pkgs.writeText "vaultwarden-database.env" ''
            DATABASE_URL=postgresql://vault@localhost/vaultwarden?host=/run/postgresql&sslmode=disable
          '')
        ];
      };
    };
}
