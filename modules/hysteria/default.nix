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
    instances = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          package = mkPackageOption pkgs "hysteria" { };
          serve = mkEnableOption (lib.mdDoc "server");
          configFile = mkOption {
            type = types.str;
            default = "/none";
          };
        };
      });
      default = [ ];
    };
  };
  config =
    mkIf (cfg.instances != [ ])
      {
        systemd.services = lib.foldr
          (s: acc: acc // {
            "hysteria-${s.name}" = {
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" "dae.service" ];
              description = "hysteria daemon";
              serviceConfig =
                let binSuffix = if s.serve then "server" else "client"; in {
                  User = "proxy";
                  ExecStart = "${lib.getExe s.package} ${binSuffix} --disable-update-check -c ${s.configFile}";
                  AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
                  Restart = "on-failure";
                };
            };
          })
          { }
          cfg.instances;
      };
}
