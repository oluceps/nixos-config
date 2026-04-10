{ lib, ... }:
{
  flake.modules.nixos.ddns-go =
    { config, lib, ... }:
    {
      options.repack.ddns-go.enable = lib.mkEnableOption "ddns-go";
      config = lib.mkIf config.repack.ddns-go.enable {
        services.ddns-go.enable = true;
      };
    };
}
