{ lib, ... }:
{
  flake.modules.nixos.aria2 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.repack.aria2.enable = lib.mkEnableOption "aria2";
      config = lib.mkIf config.repack.aria2.enable {
        systemd.user.services.aria2 = {
          description = "aria2 Daemon";
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.aria2}/bin/aria2c";
            Restart = "on-failure";
          };
        };
      };
    };
}
