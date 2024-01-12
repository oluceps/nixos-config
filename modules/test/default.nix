{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.tessst;
in
{
  options.services.tessst = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config =
    mkIf cfg.enable
      {
        systemd.services.tessst = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            User = "root";
            ExecStart = "echo $TEST";
            EnvironmentFile = pkgs.writeText "env" ''
              TEST=1
            '';
            Restart = "on-failure";
          };
        };
      }
  ;
}
