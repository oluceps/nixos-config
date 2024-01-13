{ ... }:
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

            nix = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
                mountOptions = [ "compress-force=zstd" "nosuid" "nodev" ];
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/" = {
    device = "/dev/sda3";
    fsType = "btrfs";
    options = [ "compress-force=zstd" "nosuid" "nodev" ];
  };

  fileSystems."/boot" = {
    device = "/dev/sda2";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
}
