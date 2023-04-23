{ lib, pkgs }:
{
  systemd.user = {
    sessionVariables = {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/resign.ssh";
    };
    services.resign = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit.PartOf = [ "graphical-session.target" ];
      Unit.After = [ "graphical-session.target" ];
      Service = {
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.pinentry-gnome ]}" ];
        ExecStart = "${pkgs.resign}/bin/resign --listen %t/resign.ssh";
      };
    };
  };
}
