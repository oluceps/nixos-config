{ pkgs
, config
, lib
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
    let configFile =
      pkgs.writeTextFile {
        name = "hysteria.json";
        test = builtins.toJSON (import ./config.nix);
      };
    in
    mkIf
      cfg.enable
      {
        systemd.services.hysteria = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          description = "hysteria daemon";

          serviceConfig = {
            Type = "simple";
            # User = "clash";
            # Group = "clash";
            #WorkingDirectory = "/home/riro/.config/clash-meta/";
            ExecStart = "${cfg.package}/bin/cmd -c ${configFile}";
            AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
            Restart = "on-failure";
          };
        };
      };


}



