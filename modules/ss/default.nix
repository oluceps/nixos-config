{ pkgs
, config
, lib
, user
, ...
}:
with lib;
let
  cfg = config.services.ss;
in
{
  options.services.ss = {
    enable = mkEnableOption (lib.mdDoc "shadowsocks service");

    package = mkOption {
      type = types.package;
      default = pkgs.shadowsocks-rust;
    };

    serve = mkEnableOption (lib.mdDoc "server");

    configFile = mkOption {
      type = types.str;
      default = config.age.secrets.ss.path;
    };

  };

  config = mkIf cfg.enable {
    systemd.services.ss = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "shadowsocks-rust";
      serviceConfig =
        let binSuffix = if cfg.serve then "server" else "local"; in {
          Type = "simple";
          User = "proxy";
          ExecStart = "${cfg.package}/bin/ss${binSuffix} -c ${cfg.configFile}";
          AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
          Restart = "on-failure";
        };
    };
  };
}

