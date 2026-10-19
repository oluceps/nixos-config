{
  flake.modules.nixos.loki =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      python = pkgs.python3.withPackages (p: [ p.pyyaml ]);
      overlay = pkgs.writeText "loki-realm.json" (
        builtins.toJSON {
          server = {
            http_listen_address = "127.0.0.1";
            grpc_listen_address = "127.0.0.1";
          };
          common.storage.s3 = {
            endpoint = "127.0.0.1:18333";
            insecure = true;
          };
        }
      );
    in
    {
      vaultix.secrets.loki = {
        owner = config.services.loki.user;
        group = config.services.loki.group;
        mode = "400";
      };
      services.loki = {
        enable = true;
        configFile = config.vaultix.secrets.loki.path;
      };
      realm.workloads.loki = {
        isolation.runtimePaths = [ "/run/loki" ];
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
      systemd.services.loki = {
        preStart = ''
          ${python}/bin/python3 ${../nixosModules/realm/render-yaml.py} "$CREDENTIALS_DIRECTORY/source" ${overlay} /run/loki/realm.yml
        '';
        serviceConfig = {
          RuntimeDirectory = "loki";
          RuntimeDirectoryMode = "0700";
          LoadCredential = [ "source:${config.vaultix.secrets.loki.path}" ];
          ExecStart = lib.mkForce "${config.services.loki.package}/bin/loki --config.file=/run/loki/realm.yml";
        };
      };
    };
}
