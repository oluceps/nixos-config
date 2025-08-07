{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    ;

  cfg = config.services.wg-refresh;
in
{
  options.services.wg-refresh = {
    enable = mkEnableOption { };
    tmpPath = mkOption {
      type = types.str;
      default = "/tmp/wg-refresh.json";
      description = "abs path str";
    };
    calendar = mkOption {
      type = types.str;
      description = "sd timer";
    };
  };

  config = mkIf cfg.enable {
    systemd.timers.wg-refresh = {
      description = "intime switch power mode";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.calendar;
      };
    };
    systemd.services.wg-refresh = {
      wantedBy = [ "timer.target" ];
      description = "refresh outdate addr of wg dev";
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${lib.getExe pkgs.nu} ${../script/wg-refresh.nu} ${cfg.tmpPath}";
        Restart = "on-failure";
      };
    };
  };
}
