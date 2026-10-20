{
  flake.modules.nixos.vaultwarden =
    { config, ... }:
    {
      vaultix.secrets.vault = { };
      realm.workloads.vaultwarden = {
        isolation.hosts."box.nyaw.xyz" = "127.0.0.1";
        ingress.http = {
          port = 18003;
          target = "127.0.0.1:8003";
          privateLoopback = true;
          service = "vaultwarden";
          allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
        };
        egress = {
          postgresql = {
            service = "postgresql-vaultwarden";
            verifyID = "spiffe://nyaw.xyz/service/postgresql";
            localPort = 5432;
          };
          smtp = {
            service = "smtp-submission";
            verifyID = "spiffe://nyaw.xyz/service/stalwart";
            localPort = 465;
          };
          internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/internet";
            localPort = 13128;
          };
        };
      };
      systemd.services.vaultwarden.environment = {
        HTTP_PROXY = "http://127.0.0.1:13128";
        HTTPS_PROXY = "http://127.0.0.1:13128";
        NO_PROXY = "localhost,127.0.0.1,::1,box.nyaw.xyz";
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
        environmentFile = config.vaultix.secrets.vault.path;
      };
    };
}
