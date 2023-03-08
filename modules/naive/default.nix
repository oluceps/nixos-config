{ pkgs
, config
, lib
, user
, ...
}:
with lib;
let
  cfg = config.services.naive;
in
{
  options.services.naive = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        enable?
      '';

    };
    package = mkOption {
      type = types.package;
      default = pkgs.nur-pkgs.naiveproxy;
      defaultText = literalExpression "pkgs.naiveproxy";
      description = lib.mdDoc ''
        package
      '';
    };

  };
  config =
    let
      configFile = config.age.secrets.naive.path;
      #        pkgs.writeTextFile {
      #          name = "config.json";
      #          #          destination = "dataDir/config.json";
      #          text = builtins.toJSON (import ./config.nix );
      #        };

    in
    mkIf cfg.enable {
      systemd.services.naive = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        description = "naive Daemon";

        serviceConfig = {
          Type = "simple";
          User = "proxy";
          ExecStart = "${cfg.package}/bin/naive ${configFile}";
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

