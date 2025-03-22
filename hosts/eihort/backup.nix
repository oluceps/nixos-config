{ config, lib, ... }:
{
  repack.postgresql-backup.enable = true;

  vaultix.secrets = {
   "on-yidong.toml" = {
      file = ../../sec/on-yidong.toml.age;
    };
  };
  services.rustic = {
    profiles = map (n: config.vaultix.secrets.${n}.path) [
      "general.toml"
      "on-yidong.toml"
    ];
    backups = {
      critic = {
        profiles = map (n: config.vaultix.secrets.${n}.path) [
          "general.toml"
          "on-yidong.toml"
        ];
        timerConfig = {
          OnCalendar = "*-*-1/3 03:00:00";
          RandomizedDelaySec = "4h";
          FixedRandomDelay = true;
          Persistent = true;
        };
      };
    };
  };
}
