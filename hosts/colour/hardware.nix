{ inputs, pkgs, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  zramSwap = {
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
      systemd-boot.enable = true;
      timeout = 0;
    };

    kernelParams = [
      "audit=0"
      "net.ifnames=0"
    ];

    initrd = {
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
      systemd.enable = true;
    };

    kernelPackages =
      inputs.nyx.packages.${pkgs.system}.linuxPackages_cachyos-server-lto;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  disko = {
    enableConfig = true;

    devices = {
      disk.main = {
        device = "/dev/sda";
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
                mountpoint = "/efi";
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
}
