{
  flake.modules.nixos.postgresql =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      realm.workloads.postgresql = {
        user = "postgres";
        group = "postgres";
        # Keep direct mesh TCP access while legacy clients migrate to SPIFFE.
        isolation.privateNetwork = false;
        isolation.runtimePaths = [ "/run/postgresql" ];
        ingress = {
          vaultwarden = {
            port = 15437;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-vaultwarden";
            backendUser = "realm-pg-vaultwarden";
            allowedIDs = [ "spiffe://nyaw.xyz/service/vaultwarden" ];
          };
          misskey = {
            port = 15432;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-misskey";
            backendUser = "realm-pg-misskey";
            allowedIDs = [ "spiffe://nyaw.xyz/service/misskey" ];
          };
          seaweedfs = {
            port = 15433;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-seaweedfs";
            backendUser = "realm-pg-seaweedfs";
            allowedIDs = [ "spiffe://nyaw.xyz/service/seaweedfs" ];
          };
          atuin = {
            port = 15434;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-atuin";
            backendUser = "realm-pg-atuin";
            allowedIDs = [ "spiffe://nyaw.xyz/service/atuin" ];
          };
          telegram-search = {
            port = 15436;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-telegram-search";
            backendUser = "realm-pg-telegram-search";
            allowedIDs = [ "spiffe://nyaw.xyz/service/telegram-search" ];
          };
          immich = {
            port = 15435;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-immich";
            backendUser = "realm-pg-immich";
            allowedIDs = [ "spiffe://nyaw.xyz/service/immich" ];
          };
          autopeer = {
            port = 15438;
            target = "unix:/run/postgresql/.s.PGSQL.5432";
            service = "postgresql-autopeer";
            backendUser = "realm-pg-autopeer";
            allowedIDs = [ "spiffe://nyaw.xyz/service/autopeer" ];
          };
        };
      };
      users.groups.realm-pg = { };
      users.users =
        lib.genAttrs
          [
            "realm-pg-vaultwarden"
            "realm-pg-misskey"
            "realm-pg-seaweedfs"
            "realm-pg-atuin"
            "realm-pg-immich"
            "realm-pg-telegram-search"
            "realm-pg-autopeer"
          ]
          (_: {
            isSystemUser = true;
            group = "realm-pg";
          });

      realm.observability.endpoints.postgres.port = config.services.prometheus.exporters.postgres.port;
      services.prometheus.exporters.postgres = {
        enable = true;
        listenAddress = "127.0.0.1";
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
          realm-vaultwarden realm-pg-vaultwarden vault
          realm-misskey realm-pg-misskey misskey
          realm-seaweedfs realm-pg-seaweedfs seaweed
          realm-atuin realm-pg-atuin atuin
          realm-telegram-search realm-pg-telegram-search telegram_search
          realm-immich realm-pg-immich immich
          realm-autopeer realm-pg-autopeer dn42
        '';
        # type db db_user auth_type map
        authentication = lib.mkForce ''
          local vaultwarden vault peer map=realm-vaultwarden
          local misskey misskey peer map=realm-misskey
          local seaweedfs seaweed peer map=realm-seaweedfs
          local atuin atuin peer map=realm-atuin
          local telegram_search telegram_search peer map=realm-telegram-search
          local immich immich peer map=realm-immich
          local dn42abhoth,dn42nodens,dn42yidhra dn42 peer map=realm-autopeer
          local all all peer
          host all all 127.0.0.1/32 scram-sha-256
          host all all ::1/128 scram-sha-256
        '';
      };
    };
}
