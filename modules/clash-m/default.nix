{ pkgs
, config
, lib
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
      default = pkgs.clash-meta;
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
        after = [ "network-online.target" ];
        description = "Clash-meta Daemon";

        serviceConfig = {
          Type = "simple";
          User = "proxy";
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







