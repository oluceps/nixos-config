# origin https://github.com/NullCub3/lemurs/blob/nixosmodule-dev/nix/lemurs-module.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.lemurs;
  settingsFormat = pkgs.formats.toml { };
  inherit (config.services.displayManager) sessionData;

  inherit (lib)
    mkEnableOption
    mkOption
    mkPackageOption
    ;
in
{
  options.services.lemurs = {
    enable = mkEnableOption "the Lemurs Display Manager";
    package = mkPackageOption pkgs "lemurs" { };
    settings = mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
        options = {
          tty = lib.mkOption {
            type = lib.types.int;
            default = 2;
            defaultText = lib.literalExpression "2";
            description = ''
              The tty which contains lemurs. This has to be mirrored in the lemurs.service
            '';
          };
          wayland = {
            scripts_path = lib.mkOption {
              type = lib.types.str;
              default = "/etc/lemurs/wayland";
              defaultText = lib.literalExpression "/etc/lemurs/wayland";
              description = ''
                Path to the directory where the startup scripts for the Wayland sessions are
                found
              '';
            };
            wayland_sessions_path = lib.mkOption {
              type = lib.types.str;
              default = "${sessionData.desktops.outPath}/share/wayland-sessions";
              defaultText = lib.literalExpression "/etc/lemurs/wayland";
              description = ''
                Path to the directory where the startup scripts for the Wayland sessions are
                found
              '';
            };
            # x11 etc no needed to me
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.enable = true;
    security.pam.services.lemurs = {
      allowNullPassword = true;
      startSession = true;
      # See https://github.com/coastalwhite/lemurs/issues/166
      setLoginUid = false;
      enableGnomeKeyring = lib.mkDefault config.services.gnome.gnome-keyring.enable;
    };

    systemd = {
      defaultUnit = "graphical.target";
      services = {

        lemurs =
          let
            tty = "tty${toString cfg.settings.tty}";
          in
          {
            aliases = [ "display-manager.service" ];

            unitConfig = {
              Wants = [
                "systemd-user-sessions.service"
              ];

              After = [
                "systemd-user-sessions.service"
                "plymouth-quit-wait.service"
                "getty@${tty}.service"
              ];

              Conflicts = [
                "getty@${tty}.service"
              ];
            };

            serviceConfig = {
              ExecStart =
                let
                  args = lib.cli.toGNUCommandLineShell { } {
                    wlsessions = cfg.settings.wayland.wayland_sessions_path;
                  };
                in
                "${cfg.package}/bin/lemurs --config ${settingsFormat.generate "lemurs.toml" cfg.settings} ${args}";

              StandardInput = "tty";
              TTYPath = "/dev/${tty}";
              TTYReset = "yes";
              TTYVHangup = "yes";
              Type = "idle";
            };

            restartIfChanged = false;
            wantedBy = [ "graphical.target" ];
          };
      };
    };
  };
}
