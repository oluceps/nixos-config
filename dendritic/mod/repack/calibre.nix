{ lib, ... }:
{
  flake.modules.nixos.calibre =
    { config, lib, ... }:
    {
      options.repack.calibre.enable = lib.mkEnableOption "calibre";
      config = lib.mkIf config.repack.calibre.enable {
        users.groups.calibre = { };
        services.calibre-web = {
          enable = true;
          group = "calibre";
          listen.ip = "fdcc::3";
          options = {
            calibreLibrary = "/var/lib/calibre";
            enableBookUploading = true;
            reverseProxyAuth.enable = true;
          };
        };
      };
    };
}
