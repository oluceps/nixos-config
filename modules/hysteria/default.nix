{ pkgs
, config
, lib
, user
, ...
}:
with lib;
let
  cfg = config.services.hysteria;
in
{
  options.services.hysteria = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.hysteria;
      defaultText = literalExpression "pkgs.hysteria";
      description = lib.mdDoc ''
        package
      '';

    };
  };



  config =
    let configFile = config.age.secrets.hyst.path;
    in
    mkIf
      cfg.enable
      {
        systemd.services.hysteria = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          description = "hysteria daemon";

          serviceConfig = {
            Type = "simple";
            User = user;
            ExecStart = "${cfg.package}/bin/hysteria -c ${configFile}";
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
            Restart = "on-failure";
          };
        };
      };


}



