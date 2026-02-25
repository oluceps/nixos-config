{ config, reIf, ... }:
reIf {
  services.redis.servers.ncps = {
    enable = true;
    port = 6381;
  };
  systemd.services.ncps.serviceConfig = {
    EnvironmentFile = config.vaultix.secrets.ncps.path;
  };
  vaultix.secrets.ncps = { };
  services.ncps = {
    enable = true;
    cache = {
      hostName = "cache.nyaw.xyz";
      maxSize = "200G";
      lru.schedule = "0 2 * * *";
      databaseURL = "postgresql://ncps@localhost:5432/ncps";
      storage.s3 = {
        bucket = "ncps";
        endpoint = "https://s3.nyaw.xyz";
        region = "ap-east-1";
        force-path-style = true;
      };
      redis = {
        addrs = "localhost:6381";
      };
    };
    server.addr = "[fdcc::3]:8501";
    upstream = {
      caches = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      publicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
