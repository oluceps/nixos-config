{ lib, ... }:
{
  flake.modules.nixos.earlyoom =
    { config, lib, ... }:
    {
      options.repack.earlyoom.enable = lib.mkEnableOption "earlyoom";
      config = lib.mkIf config.repack.earlyoom.enable {
        services.smartd.notifications.systembus-notify.enable = true;
        services.earlyoom = {
          enable = true;
          enableNotifications = true;
          extraArgs = [
            "--avoid"
            "bird"
          ];
        };
      };
    };
}
