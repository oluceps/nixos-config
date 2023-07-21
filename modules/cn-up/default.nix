{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.cn-up;
in
{
  options.services.cn-up = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    calendars = mkOption {
      type = types.listOf (types.str);
      default = [ "*:0/5" ];
    };

  };

  config =
    mkIf cfg.enable
      {
        systemd.timers.cn-up = {
          description = "intime shutdown";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.calendars;
          };
        };

        systemd.services.cn-up = {
          wantedBy = [ "timer.target" ];
          description = "update cn list";
          serviceConfig =
            let
              script = pkgs.writeShellApplication {
                name = "update-cn";
                text = with pkgs; ''
                  ${lib.getExe curl} -f -o /var/lib/mosdns/all_cn.txt "https://ispip.clang.cn/all_cn.txt"
                  ${lib.getExe curl} -f -o /var/lib/mosdns/accelerated-domains.china.txt "https://raw.githubusercontent.com/yubanmeiqin9048/domain/release/accelerated-domains.china.txt"
                '';
              };
            in
            {
              Type = "simple";
              User = "root";
              ExecStart = lib.getExe script;
              Restart = "on-failure";
            };
        };
      };
}
