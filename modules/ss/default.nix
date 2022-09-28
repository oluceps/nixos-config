{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.ss;
  plugin = pkgs.callPackage ./packs/v2ray-plugin/default.nix { };
in
{
  options.services.ss = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        enable?
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.shadowsocks-rust;
      defaultText = literalExpression "pkgs.shadowsocks-rust";
      description = lib.mdDoc ''
        package
      '';
    };

  };


  config =
    let
      configFile = config.age.secrets.ssconf.path;
      #        pkgs.writeTextFile {
      #          name = "shadowsocks.json";
      #          text = builtins.toJSON (import ./config.nix {inherit config;});
      #        };
    in
    mkIf cfg.enable {
      systemd.services.ss = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "shadowsocks-rust";
        serviceConfig = {
          Type = "simple";
          User = "riro";
          Group = "riro";
          #/home/riro/.config/ss/config.json
          ExecStart = "${cfg.package}/bin/sslocal -c ${configFile}";
          AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
          Restart = "on-failure";
        };

      };

    };


}

