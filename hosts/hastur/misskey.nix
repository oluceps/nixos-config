{ pkgs, ... }:
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
    "f /var/lib/misskey/config/default.yml 0644 root root - ${
      pkgs.lib.generators.toYAML { } {
        allowedPrivateNetworks = [
          "127.0.0.1/32"
          "10.0.0.1/16"
        ];
        db = {
          db = "misskey";
          host = "localhost";
          pass = "misskey";
          port = 5432;
          user = "misskey";
        };
        dbReplications = false;
        id = "aidx";
        maxFileSize = 262144000;
        outgoingAddressFamily = "dual";
        port = 3000;
        proxyBypassHosts = [
          "api.deepl.com"
          "api-free.deepl.com"
          "www.recaptcha.net"
          "hcaptcha.com"
          "challenges.cloudflare.com"
        ];
        proxyRemoteFiles = true;
        redis = {
          host = "localhost";
          port = 6379;
        };
        signToActivityPubGet = true;
        url = "https://nyaw.xyz/";
      }
    }"
  ];
}
