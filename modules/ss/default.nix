{ pkgs
, config
, lib
, user
, ...
}:
with lib;
let
  cfg = config.services.ss;
  plugin = pkgs.callPackage ../../pkgs/v2ray-plugin/default.nix { };
in
{
  options.services.ss = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    package = mkOption {
      type = types.package;
      default = pkgs.shadowsocks-rust;
    };

  };

  config =
    let
      configFile = config.rekey.secrets.ss.path;
    in
    mkIf cfg.enable {
      systemd.services.ss = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "shadowsocks-rust";
        serviceConfig = {
          Type = "simple";
          User = "proxy";
          ExecStart = "${cfg.package}/bin/sslocal -c ${configFile}";
          AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
          Restart = "on-failure";
        };

      };

    };


}

