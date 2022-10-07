{ pkgs
, config
, lib
, inputs
, system
, user
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
      default = inputs.clash-meta.packages.${system}.default;
        #inputs.clash-meta.apps.${system};
        #inputs.clash-meta.defaultPackages.${system};
        #pkgs.callPackage ../packs/clash-m { };
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
          User = "${user}";
          WorkingDirectory = "/home/${user}/.config/clash";
          ExecStart = "${cfg.package}/bin/clash-meta -d /home/${user}/.config/clash";
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







