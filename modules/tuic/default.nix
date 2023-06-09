{ pkgs
, config
, lib
, user
, ...
}:
with lib;
let
  cfg = config.services.tuic;
in
{
  options.services.tuic = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.nur-pkgs.tuic;
    };
  };

  config =
    let configFile = config.age.secrets.tuic.path;
    in
    mkIf
      cfg.enable
      {
        systemd.services.tuic = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          description = "tuic daemon";

          serviceConfig = {
            Type = "simple";
            User = "proxy";
            ExecStart = "${cfg.package}/bin/tuic-client -c ${configFile}";
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
            Restart = "on-failure";
          };
        };
      };


}



