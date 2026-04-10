{ lib, ... }:
{
  flake.modules.nixos.scrutiny =
    { config, lib, ... }:
    {
      options.repack.scrutiny.enable = lib.mkEnableOption "scrutiny";
      config = lib.mkIf config.repack.scrutiny.enable {
        systemd.services.scrutiny.after = [ "bird.service" ];
        services.scrutiny = {
          enable = true;
          collector = {
            enable = true;
            settings.api.endpoint = "https://scrutiny.nyaw.xyz";
          };

          settings = {
            web.listen = {
              port = 8090;
              host = "0.0.0.0";
            };
            openFirewall = false;
          };
        };
      };
    };
}
