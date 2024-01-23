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
          serve = mkOption {
            type = types.submodule {
              options = {
                enable = mkEnableOption (lib.mdDoc "server");
                port = mkOption { type = types.port; };
              };
            };
            default = {
              enable = false;
              port = 0;
            };
          };
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

        environment.systemPackages = lib.unique (lib.foldr
          (s: acc: acc ++ [ s.package ]) [ ]
          cfg.instances);

        networking.firewall =
          (lib.foldr
            (s: acc: acc // {
              allowedUDPPorts = mkIf s.serve.enable [ s.serve.port ];
            })
            { }
            cfg.instances);

        systemd.services = lib.foldr
          (s: acc: acc // {
            "hysteria-${s.name}" = {
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" "dae.service" ];
              wants = [ "network-online.target" ];
              description = "hysteria daemon";
              serviceConfig =
                let binSuffix = if s.serve.enable then "server" else "client"; in {
                  User = "proxy";
                  ExecStart = "${lib.getExe' s.package "hysteria"} ${binSuffix} --disable-update-check -c ${s.configFile}";
                  AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
                  Restart = "on-failure";
                };
            };
          })
          { }
          cfg.instances;
      }
  ;
}
