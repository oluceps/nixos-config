{ pkgs
, config
, lib
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
    configFile = mkOption {
      type = types.str;
      default = config.age.secrets.tuic.path;
    };
    serve = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config =
    mkIf cfg.enable
      (
        let binSuffix = if cfg.serve then "server" else "client"; in {
          systemd.services.tuic = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            description = "tuic daemon";
            serviceConfig = {
              Type = "simple";
              User = "proxy";
              ExecStart = "${cfg.package}/bin/tuic-${binSuffix} -c ${configFile}";
              AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
              Restart = "on-failure";
            };
          };
        }
      );
}



