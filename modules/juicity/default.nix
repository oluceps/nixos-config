{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.juicity;
in
{
  options.services.juicity = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.juicity;
    };
  };

  config =
    let configFile = config.age.secrets.jc-do.path;
    in
    mkIf
      cfg.enable
      {
        systemd.services.juicity = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          description = "juicity daemon";
          serviceConfig = {
            Type = "simple";
            User = "proxy";
            ExecStart = "${cfg.package}/bin/juicity-client run -c ${configFile}";
            Restart = "on-failure";
          };
        };
      };


}
