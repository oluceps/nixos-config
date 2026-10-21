{
  flake.modules.nixos.ncps =
    { config, ... }:
    {
      vaultix.secrets.ncps = {
        owner = "ncps";
        mode = "400";
      };
      systemd.services.ncps = {
        requires = [ "seaweedfs.service" ];
        serviceConfig = {
          EnvironmentFile = config.vaultix.secrets.ncps.path;
          ReadWritePaths = [ "/tmp" ];
        };
      };
      realm.observability.endpoints.ncps.socket = "/run/realm/observability/egress/ncps.sock";
      realm.workloads.observability.egress.ncps = {
        service = "ncps-metrics";
        verifyID = "spiffe://nyaw.xyz/service/ncps";
      };
      realm.workloads.ncps = {
        isolation = {
          runtimePaths = [ "/run/ncps" ];
          allowUnixSockets = [ "/run/postgresql" ];
          hosts."s3.nyaw.xyz" = "127.0.0.1";
        };
        ingress = {
          http = {
            port = 18501;
            target = "127.0.0.1:8501";
            privateLoopback = true;
            service = "ncps";
            allowedIDs = [ "spiffe://nyaw.xyz/service/nix-cache" ];
          };
          metrics = {
            port = 19501;
            target = "127.0.0.1:8501";
            privateLoopback = true;
            service = "ncps-metrics";
            allowedIDs = [ "spiffe://nyaw.xyz/service/observability-${config.networking.hostName}" ];
          };
        };
        egress = {
          s3 = {
            service = "s3-https";
            verifyID = config.realm.caddy.entrypointID;
            localPort = 443;
          };
          internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/internet";
            localPort = 13128;
          };
        };
      };
      systemd.services.ncps.environment = {
        HTTP_PROXY = "http://127.0.0.1:13128";
        HTTPS_PROXY = "http://127.0.0.1:13128";
        NO_PROXY = "localhost,127.0.0.1,::1,s3.nyaw.xyz";
      };
      services.ncps = {
        enable = true;
        cache = {
          hostName = "cache.nyaw.xyz";
          maxSize = "200G";
          lru.schedule = "0 2 * * *";
          databaseURL = "postgresql:///ncps?host=/run/postgresql";
          storage.s3 = {
            bucket = "ncps";
            endpoint = "https://s3.nyaw.xyz";
            region = "ap-east-1";
            forcePathStyle = true;
          };
          upstream = {
            urls = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://devenv.cachix.org"
            ];
            publicKeys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            ];
          };
        };
        prometheus.enable = true;
        server.addr = "127.0.0.1:8501";
      };
    };
}
