{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.rathole;
in
{
  options.services.rathole = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        enable?
      '';

    };
    package = mkOption {
      type = types.package;
      default = pkgs.rathole;
      defaultText = literalExpression "pkgs.ratholeproxy";
      description = lib.mdDoc ''
        package
      '';
    };

  };
  config =
    let
      configFile = config.age.secrets.rat.path;

    in
    mkIf cfg.enable {
      systemd.services.rathole = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "rathole Daemon";

        serviceConfig = {
          Type = "simple";
          User = "proxy";
          ExecStart = "${cfg.package}/bin/rathole -c ${configFile}";
          LimitNOFILE = 1048576;
          RestartSec = "5s";
          Restart = "on-failure";
        };

      };

    };


}

