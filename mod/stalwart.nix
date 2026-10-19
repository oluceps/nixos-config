{
  flake.modules.nixos.stalwart =
    { config, ... }:
    {
      vaultix.secrets.stalwart = {
        owner = "stalwart";
        mode = "400";
      };
      networking.firewall.allowedTCPPorts = [
        993
        25
        587
        465
        995
        4091
      ];
      systemd.services.stalwart.serviceConfig = {
        EnvironmentFile = config.vaultix.secrets.stalwart.path;
      };
      # Keep public mail protocols on the edge; mesh applications use this ingress.
      realm.workloads.stalwart = {
        runtime = "external";
        isolation.privateNetwork = false;
        ingress.submission = {
          port = 14650;
          target = "127.0.0.1:465";
          hostLoopback = true;
          consulService = "smtp-submission";
          allowedIDs = [
            "spiffe://nyaw.xyz/service/forgejo"
            "spiffe://nyaw.xyz/service/vaultwarden"
          ];
        };
      };
      services.stalwart = {
        enable = true;
      };
      realm.observability.endpoints.stalwart = {
        port = 9313;
        path = "/metrics/prometheus";
      };
    };
}
