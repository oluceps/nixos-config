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
          # debug protocols all;
          timeformat protocol iso long;

          router id 10.0.0.${toString (lib.data.node.${config.networking.hostName}.id + 1)};

          protocol device {}

          protocol direct {
              ipv6;
          };

          define SELFSET = [ fdcc::/64+ ];

          function is_self_net() -> bool
          {
            return net ~ SELFSET;
          }

          protocol kernel {
            ipv6 {
              import none;
              export filter {
                if source = RTS_STATIC then reject;
                accept;
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
