{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.srs;
in
{
  options.services.srs = {
    enable = mkEnableOption "srs server";
    package = mkPackageOption pkgs "srs" { };
    config = mkOption {
      type = types.str;
      default = "";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.srs = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "forking";
        ExecPreStart = [
          "cp -r ${cfg.package}/objs $STATE_DIRECTORY/objs"
          "ln -sfn ${cfg.package}/bin/srs $STATE_DIRECTORY/srs"
        ];
        PIDFile = "$STATE_DIRECTORY/objs/srs.pid";
        ExecStart = "$STATE_DIRECTORY/srs -c ${pkgs.writeText "srs.conf" cfg.config}";
        StateDirectory = "srs-server";
        Restart = "always";
      };
    };
  };
}
