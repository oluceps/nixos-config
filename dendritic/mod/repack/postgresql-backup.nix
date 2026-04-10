{ lib, ... }:
{
  flake.modules.nixos.postgresql-backup =
    { config, lib, ... }:
    {
      options.repack.postgresql-backup.enable = lib.mkEnableOption "postgresql-backup";
      config = lib.mkIf config.repack.postgresql-backup.enable {
        services.postgresqlBackup = {
          enable = true;
          location = "/var/lib/backup/postgresql";
          compression = "zstd";
          startAt = "*-*-* 0,12:00:00";
        };
      };
    };
}
