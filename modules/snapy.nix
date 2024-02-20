{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.snapy;
in
{
  options.services.snapy = {
    instances = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          source = mkOption {
            type = types.str;
            default = "/persist";
          };
          calendar = mkOption {
            type = types.str;
            default = "*:0/3";
          };
          keep = mkOption {
            type = types.str;
            default = "3day";
          };
        };
      });
      default = [ ];
    };
  };
  config =
    mkIf (cfg.instances != [ ])
      {

        systemd.timers = lib.foldr
          (s: acc: acc //
            {
              "snapy-${s.name}" = {
                description = "snap task ${s.name}";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnCalendar = s.calendar;
                };
              };
            })
          { }
          cfg.instances;

        systemd.services = lib.foldr
          (s: acc: acc // {
            "snapy-${s.name}" = {
              wantedBy = [ "multi-user.target" ];
              description = "${s.name} snapy daemon";
              serviceConfig =
                {
                  # DynamicUser = true;
                  User = "root";
                  ExecStart =
                    let btrfs = lib.getExe' pkgs.btrfs-progs "btrfs"; in
                    toString (pkgs.lib.getExe (pkgs.nuenv.writeScriptBin
                      {
                        name = "snapy";
                        script = ''
                          # take snapshot
                          date now | format date "%m-%d_%H:%M:%S" | ${btrfs} subvol snapshot -r ${s.source} $'${s.source}/.snapshots/($in)'

                          date now
                          # rm out-dated
                          ls ${s.source}/.snapshots | filter { |i| ((date now) - $i.modified) > ${s.keep} } | each { |d| ${btrfs} sub del $d.name }
                        '';
                      }));

                  # AmbientCapabilities = [ "CAP_SYS_ADMIN" "CAP_SYS_RESOURCE" "CAP_DAC_OVERRIDE" ];
                  # CapabilityBoundingSet = [ "CAP_SYS_ADMIN" "CAP_SYS_RESOURCE" "CAP_DAC_OVERRIDE" ];
                };
            };
          })
          { }
          cfg.instances;
      }
  ;
}
