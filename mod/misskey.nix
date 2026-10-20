{
  flake.modules.nixos.misskey =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      routes = pkgs.writeText "misskey-routes.json" (
        builtins.toJSON (
          lib.mapAttrsToList (name: route: {
            port = route.localPort;
            socket = "/realm/egress/${name}.sock";
          }) config.realm.workloads.misskey.egress
        )
      );
    in
    {
      vaultix.secrets.misskey = {
        owner = "misskey";
        mode = "400";
      };
      services.redis.servers.misskey = {
        enable = true;
        port = 0;
      };
      realm.workloads = {
        misskey = {
          unit = "podman-misskey.service";
          runtime = "container";
          ingressGroups = [ "misskey" ];
          ingress.http = {
            port = 13012;
            target = "unix:/run/realm-misskey/backend/http.sock";
            service = "misskey";
            allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
          };
          egress = {
            postgresql = {
              service = "postgresql-misskey";
              verifyID = "spiffe://nyaw.xyz/service/postgresql";
              localPort = 5432;
            };
            redis = {
              service = "redis-misskey";
              verifyID = "spiffe://nyaw.xyz/service/redis-misskey";
              localPort = 6379;
            };
            meilisearch = {
              service = "meilisearch";
              verifyID = "spiffe://nyaw.xyz/service/meilisearch";
              localPort = 7700;
            };
            s3 = {
              service = "s3-https";
              verifyID = "spiffe://nyaw.xyz/service/caddy";
              localPort = 443;
            };
            internet = {
              service = "internet-proxy";
              verifyID = "spiffe://nyaw.xyz/service/internet";
              localPort = 13128;
            };
          };
        };
        redis-misskey = {
          isolation.runtimePaths = [ "/run/redis-misskey" ];
          ingressGroups = [ "redis-misskey" ];
          ingress.redis = {
            port = 16379;
            target = "unix:/run/redis-misskey/redis.sock";
            service = "redis-misskey";
            allowedIDs = [ "spiffe://nyaw.xyz/service/misskey" ];
          };
        };
      };
      systemd.tmpfiles.rules = [
        "d /run/realm-misskey 0750 misskey realm-misskey -"
        "d /run/realm-misskey/backend 0750 misskey misskey -"
      ];
      users = {
        groups.misskey = { };
        users.misskey = {
          isSystemUser = true;
          group = "misskey";
          home = "/var/lib/misskey";
          linger = true;
          createHome = true;
          uid = 984;
          subUidRanges = [
            {
              count = 65536;
              startUid = 2147483646;
            }
          ];
          subGidRanges = [
            {
              count = 65536;
              startGid = 2147483647;
            }
          ];
        };
      };

      systemd.services.podman-misskey = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };
      virtualisation.oci-containers = {
        containers.misskey = {
          volumes =
            let
              cabundle = pkgs.cacert.override {
                extraCertificateFiles = with config.fn.pki; [
                  root_file
                ];
              };
            in
            [
              "${config.vaultix.secrets.misskey.path}:/misskey/.config/default.yml:ro"
              "${cabundle}/etc/ssl/certs/ca-bundle.crt:/misskey/ca.crt:ro"
              "${cabundle}/etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt"
              "/run/realm/misskey/egress:/realm/egress:ro"
              "/run/realm-misskey/backend:/realm/backend:rw"
              "${routes}:/realm/routes.json:ro"
              "${config.realm.helperPackage}/bin/realm-helper:/realm/helper:ro"
              "${../nixosModules/realm/container-health.cjs}:/realm/health.cjs:ro"
            ];
          # pull = "always";
          image = "misskey/misskey:latest";
          networks = [ "none" ];
          user = "1000:1000";
          # The image's tini entrypoint stays in place; tini runs the adapter,
          # which publishes the local sockets and then runs the migrate command.
          cmd = [
            "/realm/helper"
            "launch"
            "pnpm"
            "run"
            "migrateandstart"
          ];
          extraOptions = [
            "--add-host=s3.nyaw.xyz:127.0.0.1"
            "--userns=keep-id:uid=1000,gid=1000"
            "--cap-drop=ALL"
            "--security-opt=no-new-privileges"
            "--sysctl=net.ipv4.ip_unprivileged_port_start=0"
            "--health-cmd=node /realm/health.cjs"
            "--health-interval=30s"
            "--health-start-period=120s"
          ];
          podman = {
            user = "misskey";
            sdnotify = "healthy";
          };

          environment = {
            MISSKEY_CONFIG_YML = "default.yml";
            NODE_EXTRA_CA_CERTS = "/misskey/ca.crt";
          };
        };
      };
    };
}
