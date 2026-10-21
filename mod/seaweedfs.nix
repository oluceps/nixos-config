{
  flake.modules.nixos.seaweedfs =
    { config, pkgs, ... }:
    let
      # filerDir = "/var/lib/sea-filer";
      dataDir = "/var/lib/sea-volume";
      filerConfig = builtins.fromTOML (builtins.readFile ./filer.toml);
    in
    {
      realm.observability.endpoints.seaweedfs.socket = "/run/realm/observability/egress/seaweedfs.sock";
      realm.workloads.observability.egress.seaweedfs = {
        service = "seaweedfs-metrics";
        verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
      };
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
        ingress = {
          s3 = {
            port = 18333;
            target = "127.0.0.1:8333";
            privateLoopback = true;
            service = "seaweedfs-s3";
            allowedIDs = [
              "spiffe://nyaw.xyz/service/loki"
            ]
            ++ config.realm.caddy.allowedIDs.seaweedfs-s3
            ++ [
              "spiffe://nyaw.xyz/service/synapse"
              "spiffe://nyaw.xyz/service/synapse-s3-upload"
            ];
          };
          master = {
            port = 19333;
            target = "127.0.0.1:9333";
            privateLoopback = true;
            service = "seaweedfs-master";
            allowedIDs = config.realm.caddy.allowedIDs.seaweedfs-master;
          };
          metrics = {
            port = 19768;
            target = "127.0.0.1:9768";
            privateLoopback = true;
            service = "seaweedfs-metrics";
            allowedIDs = [ "spiffe://nyaw.xyz/service/observability-${config.networking.hostName}" ];
          };
        };
      };
      systemd.services.seaweedfs.after = [ "postgresql.target" ];
      systemd.services.seaweedfs.requires = [ "postgresql.target" ];
      systemd.services.seaweedfs.serviceConfig = {
        BindReadOnlyPaths = [ "/run/postgresql" ];
        RuntimeDirectory = "seaweedfs";
        LoadCredential = [ "weed-s3:${config.vaultix.secrets.weed-s3.path}" ];
        ReadWritePaths = [
          dataDir
          # SeaweedFS creates its local master gRPC sockets and scratch files here.
          "/tmp"
        ];
        MemoryMax = "8G";
        MemoryHigh = "6G";
        Environment = [ "GOMEMLIMIT=6GiB" ];
      };

      environment.etc."seaweedfs/filer.toml".source = (pkgs.formats.toml { }).generate "filer.toml" (
        filerConfig
        // {
          postgres2 = filerConfig.postgres2 // {
            hostname = "/run/postgresql";
            password = "";
          };
        }
      );
    };
}
