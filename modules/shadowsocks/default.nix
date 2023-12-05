{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.shadowsocks;
in
{
  options.services.shadowsocks = {
    instances = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          package = mkPackageOption pkgs "shadowsocks-rust" { };
          serve = mkEnableOption (lib.mdDoc "server");
          configFile = mkOption {
            type = types.str;
            default = "/none";
          };
        };
      });
    };
  };

  config =
    mkIf (cfg.instances != [ ])
      {
        systemd.services = lib.foldr
          (s: acc: acc // {
            "shadowsocks-${s.name}" = {
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              description = "shadowsocks-rust";
              serviceConfig =
                let binSuffix = if s.serve then "server" else "local"; in {
                  Type = "simple";
                  User = "proxy";
                  ExecStart = "${s.package}/bin/ss${binSuffix} -c ${s.configFile}";
                  AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
                  Restart = "on-failure";
                };
            };
          })
          { }
          cfg.instances;
      };
}


