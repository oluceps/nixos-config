{
  flake.modules.nixos.postgresql =
    {
      lib,
      pkgs,
      ...
    }:
    {
      realm.workloads.postgresql = {
        user = "postgres";
        group = "postgres";
        isolation.runtimePaths = [ "/run/postgresql" ];
        ingress = {
          misskey = {
            port = 15432;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            consulService = "postgresql-misskey";
            backendUser = "realm-pg-misskey";
            allowedIDs = [ "spiffe://nyaw.xyz/service/misskey" ];
          };
          seaweedfs = {
            port = 15433;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            consulService = "postgresql-seaweedfs";
            backendUser = "realm-pg-seaweedfs";
            allowedIDs = [ "spiffe://nyaw.xyz/service/seaweedfs" ];
          };
          atuin = {
            port = 15434;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            consulService = "postgresql-atuin";
            backendUser = "realm-pg-atuin";
            allowedIDs = [ "spiffe://nyaw.xyz/service/atuin" ];
          };
        };
      };
      users.groups.realm-pg = { };
      users.users = lib.genAttrs [ "realm-pg-misskey" "realm-pg-seaweedfs" "realm-pg-atuin" ] (_: {
        isSystemUser = true;
        group = "realm-pg";
      });

      services.prometheus.exporters.postgres = {
        enable = true;
        listenAddress = "[::]";
        runAsLocalSuperUser = true;
      };
      systemd.services.postgresql.serviceConfig = {
        ReadWritePaths = [ "/pool0/relation" ];
      };
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17_jit;
        extensions = ps: [
          ps.pgvector
          ps.vectorchord
        ];
        enableTCPIP = false;
        settings = {
          allow_alter_system = false;
          port = 5432;
          wal_buffers = "16MB";
          work_mem = "38836kB";
          huge_pages = "try";
          max_worker_processes = 8;
          max_parallel_workers_per_gather = 4;
          max_parallel_workers = 8;
          max_parallel_maintenance_workers = 4;
          max_connections = 100;
          shared_buffers = "8GB";
          effective_cache_size = "24GB";
          maintenance_work_mem = "2GB";
          checkpoint_completion_target = 0.9;
          default_statistics_target = 100;
          random_page_cost = 1.1;
          effective_io_concurrency = 200;
          min_wal_size = "2GB";
          max_wal_size = "8GB";
          shared_preload_libraries = "vchord.so,pg_stat_statements";
          "pg_stat_statements.track" = "top";
          search_path = "\"$user\", public, vectors";
        };

        # map_name connect_unix_user db_user
        identMap = ''
          realm-misskey realm-pg-misskey misskey
          realm-seaweedfs realm-pg-seaweedfs seaweed
          realm-atuin realm-pg-atuin atuin
        '';
        # type db db_user auth_type map
        authentication = lib.mkForce ''
          local misskey misskey peer map=realm-misskey
          local seaweedfs seaweed peer map=realm-seaweedfs
          local atuin atuin peer map=realm-atuin
          local all all peer
        '';
      };
    };
}
