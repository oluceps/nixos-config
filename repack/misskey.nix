{
  reIf,
  lib,
  config,
  pkgs,
  ...
}:
reIf {
  services.redis.servers.misskey = {
    enable = true;
    port = 6379;
  };
  users = {
    groups.misskey = { };
    users.misskey = {
      isSystemUser = true;
      group = "misskey";
      home = "/var/lib/misskey";
      linger = true;
      createHome = true;
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

  virtualisation.oci-containers = {
    containers.misskey = {
      volumes = [
        "${config.vaultix.secrets.misskey.path}:/misskey/.config/config:ro"
        "${
          pkgs.cacert.override {
            extraCertificateFiles = with lib.data.ca; [
              root
              intermediate
            ];
          }
        }:/misskey/ca.crt:ro"
      ];
      # pull = "always";
      image = "misskey/misskey:2025.4.1";
      networks = [
        "pasta:-T,5432,-T,6379,-T,7700"
      ];
      podman = {
        user = "misskey";
        sdnotify = "healthy";
      };

      environment = {
        MISSKEY_CONFIG_YML = "config";
        NODE_EXTRA_CA_CERTS = "/misskey/ca.crt";
      };
    };
  };
  # systemd.services.podman-misskey.serviceConfig.LoadCredential = [
  #   "config:${config.vaultix.secrets.misskey.path}"
  # ];
}
