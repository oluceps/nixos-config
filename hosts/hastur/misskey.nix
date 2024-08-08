{ config, pkgs, ... }:
{
  services.redis.servers.misskey = {
    enable = true;
    port = 6379;
  };

  systemd.services.podman-misskey = {
    after = [
      "dae.service"
      "mosproxy.service"
    ];
    requires = [
      "dae.service"
      "mosproxy.service"
    ];
  };

  virtualisation = {
    oci-containers.backend = "podman";
    oci-containers.containers = {
      misskey = {
        image = "docker.io/misskey/misskey:2024.7.0";
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
    "C+ /var/lib/misskey/config/default.yml 0744 - - - ${config.age.secrets.misskey.path}"
  ];
}
