{ lib, pkgs, ... }:
{
  systemd.user = {
    services.element-web = {
      Install.WantedBy = [ "graphical-session.target" ];
      Unit.PartOf = [ "graphical-session.target" ];
      Unit.After = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${lib.getExe pkgs.miniserve} -p 3440 --index ${pkgs.element-web}/index.html";
      };
    };
  };
}
