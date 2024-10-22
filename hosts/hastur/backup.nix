{ config, lib, ... }:
{
  repack.postgresql-backup.enable = true;
  systemd.services.postgresqlBackup.onSuccess = "rustic-backups-critic.service";
  services.rustic = {
    backups = {
      critic = {
        profiles = map (n: config.age.secrets.${n}.path) [
          "general.toml"
          "on-kaambl.toml"
        ];
      };

      solid = {
        profiles = map (n: config.age.secrets.${n}.path) [
          "general.toml"
          "on-eihort.toml"
        ];
        timerConfig = {
          OnCalendar = "*-*-* 3,15:00:00";
          RandomizedDelaySec = "4h";
          FixedRandomDelay = true;
          Persistent = true;
        };
      };
    };
  };
}
