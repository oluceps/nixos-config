{
  flake.modules.nixos.seaweedfs =
    { config, ... }:
    let
      # filerDir = "/var/lib/sea-filer";
      dataDir = "/var/lib/sea-volume";
    in
    {
      vaultix.secrets.weed-s3 = {
        owner = "seaweedfs";
        group = "seaweedfs";
      };
      services.seaweedfs = {
        enable = true;
        args = [
          "server"
          "-ip"
          "127.0.0.1"
          "-s3"
          "-s3.config=\${CREDENTIALS_DIRECTORY}/weed-s3"
          "-s3.allowEmptyFolder=false"
          "-filer"
          "-filer.port=8889"
          "-dir=${dataDir}"
          "-volume.max=0"
          "-volume.hasSlowRead=false"
          "-volume.readBufferSizeMB=16"
          "-metricsIp=127.0.0.1"
          "-metricsPort=9768"
        ];
      };
      realm.workloads.seaweedfs = {
        isolation.runtimePaths = [ "/run/seaweedfs" ];
        egress.postgresql = {
          service = "postgresql-seaweedfs";
          verifyID = "spiffe://nyaw.xyz/service/postgresql";
          localPort = 5432;
        };
        ingress = {
          s3 = {
            port = 18333;
            target = "127.0.0.1:8333";
            privateLoopback = true;
            consulService = "seaweedfs-s3";
            allowedIDs = [
              "spiffe://nyaw.xyz/service/loki"
              "spiffe://nyaw.xyz/service/caddy"
            ];
          };
          master = {
            port = 19333;
            target = "127.0.0.1:9333";
            privateLoopback = true;
            consulService = "seaweedfs-master";
            allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
          };
          metrics = {
            port = 19768;
            target = "127.0.0.1:9768";
            privateLoopback = true;
            consulService = "seaweedfs-metrics";
            allowedIDs = [ "spiffe://nyaw.xyz/service/vmagent" ];
          };
        };
      };
      systemd.services.seaweedfs.serviceConfig = {
        RuntimeDirectory = "seaweedfs";
        LoadCredential = [ "weed-s3:${config.vaultix.secrets.weed-s3.path}" ];
        ReadWritePaths = [
          dataDir
        ];
        MemoryMax = "8G";
        MemoryHigh = "6G";
        Environment = [ "GOMEMLIMIT=6GiB" ];
      };

      environment.etc."seaweedfs/filer.toml".source = ./filer.toml;
    };
}
