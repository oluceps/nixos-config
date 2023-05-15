{ pkgs, lib, ... }: {
  systemd.user.services.swww = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${lib.getExe pkgs.swww} init";
      Restart = "on-failure";
    };

    Install = { WantedBy = [ "sway-session.target" ]; };
  };
}
