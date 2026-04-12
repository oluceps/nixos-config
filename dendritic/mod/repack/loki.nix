{
  flake.modules.nixos.loki =
    { config, ... }:
    {
      vaultix.secrets.loki = {
        owner = "loki";
        mode = "400";
      };
      services.loki = {
        enable = true;
        configFile = config.vaultix.secrets.loki.path;
      };
    };
}
