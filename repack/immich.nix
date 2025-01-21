{ reIf, config, ... }:
reIf {
  services = {
    immich = {
      enable = true;
      host = "0.0.0.0";
      secretsFile = config.vaultix.secrets.immich.path;
      database.createDB = false;
      machine-learning.enable = true;
      redis.enable = true;
    };
    immich-public-proxy = {
      enable = true;
      immichUrl = "https://photo.nyaw.xyz";
    };
  };
}
