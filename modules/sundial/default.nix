{ pkgs
, config
, lib
, user
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

    calendars = mkOption {
      type = types.listOf (types.str);
      default = [ "Sun-Thu 23:18:00" "Fri,Sat 23:48:00" ];
    };

    warnAt = mkOption {
      type = types.listOf (types.str);
      default = [ ];
    };
  };

  config =
    mkIf cfg.enable
      {

        systemd.timers.sundial = {
          description = "intime shutdown";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.calendars;
          };
        };

        systemd.timers.sundial-warnner = {
          description = "notify before shutdown";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.warnAt;
          };
        };

        systemd.services.sundial-warnner = {
          wantedBy = [ "timer.target" ];
          description = "notify before auto shutdown";
          serviceConfig = {
            Type = "simple";
            User = user;
            Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
            ExecStart = "${pkgs.libnotify}/bin/notify-send -u critical SHUTDOWN INCOMMING";
            Restart = "on-failure";
          };
        };

        systemd.services.sundial = {
          wantedBy = [ "timer.target" ];
          description = "shutdown";
          serviceConfig = {
            Type = "simple";
            User = "root";
            ExecStart = "poweroff";
            Restart = "on-failure";
          };
        };
      };
}
