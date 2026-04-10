{ lib, ... }:
{
  flake.modules.nixos.arti =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.repack.arti.enable = lib.mkEnableOption "arti";
      config = lib.mkIf config.repack.arti.enable {
        systemd.user.services.arti = {
          wantedBy = [ "default.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.arti} proxy";
            Restart = "always";
          };
        };
      };
    };
}
