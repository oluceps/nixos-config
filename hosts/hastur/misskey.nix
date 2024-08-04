{ config, pkgs, ... }:
{
  services.redis.servers.misskey = {
    enable = true;
    port = 6379;
  };

  virtualisation = {
    oci-containers.backend = "podman";
    oci-containers.containers = {
      misskey = {
        image = "docker.io/misskey/misskey:latest";
        ports = [ "3000:3000/tcp" ];
        volumes = [
          "/var/lib/misskey/files:/misskey/files"
          "/var/lib/misskey/config:/misskey/.config"
        ];
        extraOptions = [ "--network=host" ];
      };
    };
  };
  systemd.tmpfiles.rules = [
    "C+ /var/lib/misskey/config/default.yml 0755 - - - ${config.age.secrets.misskey.path}"
  ];
}
