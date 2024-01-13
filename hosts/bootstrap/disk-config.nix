{ lib, ... }:
{

  disko = {
    enableConfig = false;

    devices = {
      disk.main = {
        imageSize = "2G";
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 0;
            };

            ESP = {
              name = "ESP";
              size = "512M";
              type = "EF00";
              priority = 1;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };

            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "--csum xxhash64" ];
                subvolumes = {
                  "root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                  };
                  "home" = {
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                    mountpoint = "/home";
                  };
                  "nix" = {
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                    mountpoint = "/nix";
                  };
                  "var" = {
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                    mountpoint = "/var";
                  };
                };
              };
            };
          };
        };
      };
    };
  };


  # manual
  fileSystems = ({
    "/boot" = {
      device = "/dev/sdb2";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
    "/" = {
      device = "/dev/sdb2";
      fsType = "vfat";
      options = [ "subvol=/root" "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" ];
    };
  } // lib.genAttrs [ "home" "nix" "var" ] (name:
    {
      device = "/dev/sdb3";
      fsType = "btrfs";
      options = [ "subvol=/${name}" "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
    }
  ));
}
 
