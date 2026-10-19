{
  flake.modules.nixos.synapse =
    {
      lib,
      config,
      utils,
      pkgs,
      ...
    }:
    let
      s3 = {
        bucket = "synapse";
        endpoint_url = "http://127.0.0.1:18333";
      };
      caBundleEnv = "AWS_CA_BUNDLE=${config.fn.pki.root_file}";
      inherit (config.services.matrix-synapse.settings) media_store_path;
    in
    {
      vaultix.secrets = {
        synapse-oidc = {
          owner = config.systemd.services.matrix-synapse.serviceConfig.User;
          mode = "400";
        };
        synapse-s3 = { };
      };

      realm.observability.endpoints.synapse = {
        socket = "/run/realm/observability/egress/synapse.sock";
        path = "/_synapse/metrics";
      };
      realm.workloads.observability.egress.synapse = {
        service = "synapse-metrics";
        verifyID = "spiffe://nyaw.xyz/service/synapse";
      };
      realm.workloads = {
        synapse = {
          unit = "matrix-synapse.service";
          user = "matrix-synapse";
          group = "matrix-synapse";
          isolation = {
            runtimePaths = [ "/run/matrix-synapse" ];
            allowUnixSockets = [ "/run/postgresql" ];
          };
          ingress = {
            http = {
              port = 18196;
              target = "127.0.0.1:8196";
              privateLoopback = true;
              consulService = "synapse";
              allowedIDs = [
                "spiffe://nyaw.xyz/service/caddy"
                "spiffe://nyaw.xyz/service/mautrix-telegram"
              ];
            };
            metrics = {
              port = 19031;
              target = "127.0.0.1:9031";
              privateLoopback = true;
              consulService = "synapse-metrics";
              allowedIDs = [ "spiffe://nyaw.xyz/service/observability-${config.networking.hostName}" ];
            };
          };
          egress = {
            s3 = {
              service = "seaweedfs-s3";
              verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
              localPort = 18333;
            };
            internet = {
              service = "internet-proxy";
              verifyID = "spiffe://nyaw.xyz/service/internet";
              localPort = 13128;
            };
            telegram = {
              service = "mautrix-telegram";
              verifyID = "spiffe://nyaw.xyz/service/mautrix-telegram";
              localPort = 29317;
            };
          };
        };
        synapse-s3-upload = {
          unit = "matrix-synapse-s3-upload.service";
          user = "matrix-synapse";
          group = "matrix-synapse";
          isolation = {
            runtimePaths = [ "/run/matrix-synapse-s3-upload" ];
            allowUnixSockets = [ "/run/postgresql" ];
          };
          egress.s3 = {
            service = "seaweedfs-s3";
            verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
            localPort = 18333;
          };
        };
      };
      services.matrix-synapse = {
        enable = true;
        withJemalloc = true;
        plugins = with config.services.matrix-synapse.package.plugins; [
          matrix-synapse-s3-storage-provider
        ];
        settings = {
          server_name = "nyaw.xyz";
          public_baseurl = "https://matrix.nyaw.xyz";
          enable_authenticated_media = true;
          enable_metrics = true;
          dynamic_thumbnails = true;
          allow_public_rooms_over_federation = true;

          enable_registration = true;
          registration_requires_token = true;
          database.args.host = "/run/postgresql";

          media_storage_providers = [
            {
              module = "s3_storage_provider.S3StorageProviderBackend";
              store_local = true;
              store_remote = true;
              store_synchronous = true;
              config = {
                inherit (s3) bucket endpoint_url;
              };
            }
          ];
          oidc_providers = [
            {
              client_id = "7eac9a65-1ebb-4185-a8ec-17c3b614d6cd";
              client_secret_path = "/run/credentials/matrix-synapse.service/oidc-secret";
              idp_id = "pocket_id";
              idp_name = "Pocket ID";
              issuer = "https://oidc.nyaw.xyz/";

              allow_existing_users = false;
              backchannel_logout_enabled = true;

              scopes = [
                "openid"
                "profile"
              ];
              user_mapping_provider = {
                config = {
                  display_name_template = "{{ user.name }}";
                  localpart_template = "{{ user.preferred_username }}";
                };
              };
            }
          ];

          listeners = [
            {
              port = 9031;
              type = "metrics";
              bind_addresses = [ "127.0.0.1" ];
              tls = false;
              resources = [ ];
            }
            {
              bind_addresses = [ "127.0.0.1" ];
              port = 8196;
              tls = false;
              type = "http";
              x_forwarded = true;
              resources = [
                {
                  compress = true;
                  names = [
                    "client"
                    "federation"
                  ];
                }
              ];
            }
          ];

          media_retention = {
            remote_media_lifetime = "14d";
          };

          experimental_features = {
            msc3266_enabled = true;
            msc3391_enabled = true;
            msc3773_enabled = true;
            msc3881_enabled = true;
            msc3890_enabled = true;
            msc4210_enabled = true;
          };

          rc_admin_redaction = {
            per_second = 1000;
            burst_count = 10000;
          };
        };
      };

      systemd.timers.matrix-synapse-s3-upload = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          FixedRandomDelay = true;
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "4h";
        };
      };

      systemd.services.matrix-synapse-s3-upload.serviceConfig = {
        Type = "oneshot";
        inherit (config.systemd.services.matrix-synapse.serviceConfig) User Group;
        Environment = [ caBundleEnv ];
        EnvironmentFile = [ config.vaultix.secrets.synapse-s3.path ];
        RuntimeDirectory = [ "matrix-synapse-s3-upload" ];
        WorkingDirectory = "%t/matrix-synapse-s3-upload";
        BindReadOnlyPaths = [
          "${
            (pkgs.formats.yaml { }).generate "database.yaml" {
              postgres = {
                inherit (config.services.matrix-synapse.settings.database.args) database user;
                host = "/run/postgresql";
              };
            }
          }:%t/matrix-synapse-s3-upload/database.yaml"
        ];
        ExecStart = with config.services.matrix-synapse.package.plugins; [
          (utils.escapeSystemdExecArgs [
            (lib.getExe matrix-synapse-s3-storage-provider)
            "--no-progress"
            "update"
            media_store_path
            "1h"
          ])
          (utils.escapeSystemdExecArgs [
            (lib.getExe matrix-synapse-s3-storage-provider)
            "--no-progress"
            "upload"
            "--delete"
            "--endpoint-url"
            s3.endpoint_url
            media_store_path
            s3.bucket
          ])
        ];
      };

      systemd.services.matrix-synapse.serviceConfig = {
        LoadCredential = [ "oidc-secret:${config.vaultix.secrets.synapse-oidc.path}" ];
        Environment = [
          "AWS_REQUEST_CHECKSUM_CALCULATION=when_required"
          "AWS_RESPONSE_CHECKSUM_VALIDATION=when_required"
          caBundleEnv
        ];
        EnvironmentFile = [
          config.vaultix.secrets.synapse-s3.path
        ];
      };
      systemd.services.matrix-synapse.after = [ "postgresql.service" ];
      systemd.services.matrix-synapse.requires = [ "postgresql.service" ];
      systemd.services.matrix-synapse-s3-upload.after = [ "postgresql.service" ];
      systemd.services.matrix-synapse-s3-upload.requires = [ "postgresql.service" ];
      systemd.services.matrix-synapse.environment = {
        HTTP_PROXY = "http://127.0.0.1:13128";
        HTTPS_PROXY = "http://127.0.0.1:13128";
        NO_PROXY = "localhost,127.0.0.1,::1";
      };

    };
}
