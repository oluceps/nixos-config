{ config, lib, ... }:
{
  systemd.services =
    lib.genAttrs (map (n: "restic-backups-${n}") (lib.attrNames config.services.restic.backups))
      {
        serviceConfig.Environment = [ "GOGC=20" ];
      };

  services.restic = {
    backups = {
      # solid = {
      #   passwordFile = config.age.secrets.wg.path;
      #   repositoryFile = config.age.secrets.restic-repo.path;
      #   environmentFile = config.age.secrets.restic-envs.path;
      #   paths = [
      #     "/persist"
      #     "/var"
      #   ];
      #   extraBackupArgs = [
      #     "--one-file-system"
      #     "--exclude-caches"
      #     "--no-scan"
      #     "--retry-lock 2h"
      #   ];
      #   timerConfig = {
      #     OnCalendar = "daily";
      #     RandomizedDelaySec = "4h";
      #     FixedRandomDelay = true;
      #     Persistent = true;
      #   };
      # };
      critic = {
        #### CLOUDFLARE R2 but connectivity bad
        #   passwordFile = config.age.secrets.wg.path;
        #   repositoryFile = config.age.secrets.restic-repo-crit.path;
        #   environmentFile = config.age.secrets.restic-envs-crit.path;
        passwordFile = config.age.secrets.wg.path;
        repository = "s3:http://10.0.1.3:3900/crit";
        environmentFile = config.age.secrets.restic-envs-dc3.path;
        ####
        paths = [
          "/var/.snapshots/latest/lib/backup"
          "/var/.snapshots/latest/lib/private/matrix-conduit"
        ];
        extraBackupArgs = [
          "--exclude-caches"
          "--no-scan"
          "--retry-lock 2h"
        ];
        pruneOpts = [ "--keep-daily 3" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "4h";
          FixedRandomDelay = true;
          Persistent = true;
        };
      };
    };
  };
}
