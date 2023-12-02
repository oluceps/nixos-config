{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.sundial;
in
{
  options.services.sundial = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    powersave-calendars = mkOption {
      type = types.listOf types.str;
      default = [ "Sun-Thu 23:18:00" "Fri,Sat 23:48:00" ];
    };

    performance-calendars = mkOption {
      type = types.listOf types.str;
      default = [ "Sun-Thu 06:00:00" "Fri,Sat 06:00:00" ];
    };

    warnAt = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config =
    mkIf cfg.enable
      {

        systemd.timers = with builtins; listToAttrs (map
          (mode: {
            name = "sundial-${mode}";
            value = {
              description = "intime switch power mode";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = cfg."${mode}-calendars";
              };
            };
          }) [ "performance" "powersave" ]);


        systemd.services = with builtins; listToAttrs (map
          (mode: {
            name = "sundial-${mode}";
            value = {
              wantedBy = [ "timer.target" ];
              description = "turn power mode to ${mode}";
              serviceConfig = {
                Type = "simple";
                User = "root";
                ExecStart = "${lib.getExe pkgs.linuxKernel.packages.linux_latest_libre.cpupower} frequency-set -g ${mode}";
                Restart = "on-failure";
              };
            };
          }) [ "performance" "powersave" ]);
      };
}
