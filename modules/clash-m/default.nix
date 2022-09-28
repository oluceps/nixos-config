{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.clash;
in
{
  options.services.clash = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../packs/clash-m { };
      defaultText = literalExpression "pkgs.clash-meta";
      description = lib.mdDoc ''
        package
      '';
    };

  };
  config =
    mkIf cfg.enable {
      systemd.services.clash = {

        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "Clash-meta Daemon";

        serviceConfig = {
          Type = "simple";
          User = "riro";
          WorkingDirectory = "/home/riro/.config/clash";
          ExecStart = "${cfg.package}/bin/clash -d /home/riro/.config/clash";
          CapabilityBoundingSet = [
            "CAP_NET_RAW"
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          AmbientCapabilities = [
            "CAP_NET_RAW"
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          Restart = "on-failure";
        };

      };

    };


}







