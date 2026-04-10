{ lib, ... }:
{
  flake.modules.nixos.mysql =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.repack.mysql.enable = lib.mkEnableOption "mysql";
      config = lib.mkIf config.repack.mysql.enable {
        services.mysql = {
          enable = true;
          package = pkgs.mariadb_114;
          dataDir = "/var/lib/mysql";
        };
      };
    };
}
