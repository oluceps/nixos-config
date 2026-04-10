{ lib, ... }:
{
  flake.modules.nixos.subs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.repack.subs;
    in
    {
      options.repack.subs = {
        enable = lib.mkEnableOption "subs";
        scriptPath = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/private/subs/subs.ts";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.subs = {
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig.Type = "simple";
          serviceConfig.User = config.identity.user;
          serviceConfig.ExecStart = "${lib.getExe pkgs.deno} run --allow-env --allow-net --no-check ${cfg.scriptPath}";
          serviceConfig.Restart = "always";
          serviceConfig.RestartSec = 1;
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
        };
      };
    };
}
