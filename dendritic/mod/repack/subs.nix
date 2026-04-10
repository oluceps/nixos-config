{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.subs;
in
{
  options.subs = {
    enable = lib.mkEnableOption "subs";
    scriptPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/private/subs/subs.ts";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "riro";
    };
  };

  flake.modules.nixos.subs = lib.mkIf cfg.enable {
    systemd.services.subs = {
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig.Type = "simple";
      serviceConfig.User = cfg.user;
      serviceConfig.ExecStart = "${lib.getExe pkgs.deno} run --allow-env --allow-net --no-check ${cfg.scriptPath}";
      serviceConfig.Restart = "always";
      serviceConfig.RestartSec = 1;
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
