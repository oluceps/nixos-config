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
    configFile = mkOption {
      type = types.str;
      default = config.age.secrets.jc-do.path;
    };
    serve = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config =
    mkIf
      cfg.enable
      (
        let binSuffix = if cfg.serve then "server" else "client"; in {
          systemd.services.juicity = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            description = "juicity daemon";
            serviceConfig = {
              Type = "simple";
              User = "proxy";
              ExecStart = "${cfg.package}/bin/juicity-${binSuffix} run -c ${cfg.configFile}";
              Restart = "on-failure";
            };
          };
        }
      );
}
