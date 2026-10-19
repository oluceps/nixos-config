{
  flake.modules.nixos.loki =
    {
      config,
      ...
    }:
    {
      vaultix.secrets.loki = {
        owner = config.services.loki.user;
        group = config.services.loki.group;
        mode = "400";
      };
      services.loki = {
        enable = true;
        configFile = "/run/credentials/loki.service/config";
        # All components share a loopback-only namespace; avoid interface discovery.
        extraFlags = [
          "-common.storage.ring.instance-addr=127.0.0.1"
          "-memberlist.advertise-addr=127.0.0.1"
          "-memberlist.bind-addr=127.0.0.1"
          "-frontend.instance-addr=127.0.0.1"
        ];
      };
      realm.workloads.loki = {
        egress.s3 = {
          service = "seaweedfs-s3";
          verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
          localPort = 18333;
        };
        ingress.http = {
          port = 19429;
          target = "127.0.0.1:3030";
          privateLoopback = true;
          consulService = "loki";
          allowedIDs = [
            "spiffe://nyaw.xyz/service/alloy"
            "spiffe://nyaw.xyz/service/grafana"
          ];
        };
      };
      systemd.services.loki.serviceConfig.LoadCredential = [
        "config:${config.vaultix.secrets.loki.path}"
      ];
    };
}
