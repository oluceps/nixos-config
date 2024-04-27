{
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  cfg = config.programs.swww;
in
{
  options.programs.swww = {
    enable = lib.options.mkEnableOption "swww";
  };
  config = lib.mkIf cfg.enable {

    systemd.user.services.swww-daemon = {
      Unit = {
        Requires = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "notify";
        ExecStart = "${pkgs.swww}/bin/swww-daemon";
        Restart = "on-failure";
        Environment = [
          "WAYLAND_DISPLAY=wayland-1"
          "XDG_RUNTIME_DIR=/run/user/1000"
          "PATH=${
            lib.makeBinPath [
              pkgs.procps
              pkgs.swww
            ]
          }"
        ];
      };
      Install = {
        WantedBy = [ "sway-session.target" ];
      };
    };

    # systemd.user.services.swww = {
    #   Unit = {
    #     PartOf = [ "graphical-session.target" ];
    #     After = [ "graphical-session.target" ];
    #   };
    #   Service = {
    #     Restart = "on-failure";
    #     Type = "oneshot";
    #     Environment = [
    #       "XDG_CACHE_HOME=/home/${user}/.cache"
    #       "HOME=/home/${user}"
    #       "WAYLAND_DISPLAY=wayland-1"
    #       "DISPLAY=:0"
    #     ];
    #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
    #     ExecStart = ''
    #       ${pkgs.swww}/bin/swww img -o eDP-1 --resize=fit -f Nearest /nix/store/knnnzbvma1vsn7vw0464dmgl1lyfpn6n-u6-2160x1440.gif
    #       # $\{
    #       #   pkgs.fetchurl {
    #       #     url = "https://s3.nyaw.xyz/misc/u6-2160x1440.gif";
    #       #     hash = "";
    #       #   }
    #       # }
    #     '';
    #   };

    #   Install = {
    #     WantedBy = [ "sway-session.target" ];
    #   };
    # };
  };
}
