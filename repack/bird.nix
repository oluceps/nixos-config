{
  lib,
  config,
  ...
}:
let
  cfg = config.repack.bird;
in
{

  options = {
    repack.bird = {
      baseConfig = lib.mkOption {
        type = lib.types.lines;
        readOnly = true;
        default = ''
          log syslog all;
          debug protocols all;
          timeformat protocol iso long;

          router id 10.0.0.${toString (lib.data.node.${config.networking.hostName}.id + 1)};

          protocol device {
            scan time 20;
          }

          protocol direct {
            ipv6;
            interface "wg-*";
          };

          define INTRA_FIELD = [ fdcc::/64+ ];

          filter intranet {
            if net ~ INTRA_FIELD then {
              if source = RTS_BABEL || source = RTS_DEVICE then accept;
            }
            reject;
          }

          protocol kernel {
            ipv6 {
              import none;
              export filter {
                if source = RTS_BABEL then {
                  krt_prefsrc = ${lib.getIntraAddr config};
                  krt_metric = 128;
                  accept;
                }
                if source = RTS_DEVICE then {
                  krt_metric = 64;
                  accept;
                }

                reject;
              };
            };
          };
        '';
      };
      config = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };
    };
  };
  config = {
    services.bird = {
      enable = true;
      config = cfg.baseConfig + cfg.config;
    };
  };
}
