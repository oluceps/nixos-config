{ config, inputs, pkgs, lib, modulesPath, ... }:

{

  zramSwap = {
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  systemd.services.zfs-mount.enable = true;
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
      systemd-boot.enable = true;
      timeout = 3;
    };

    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    zfs.extraPools = [ "PoolOne" ];

    kernelParams = [
      "audit=0"
      "net.ifnames=0"

      # "console=ttyS0"
      # "earlyprintk=ttyS0"
      # "rootdelay=300"
    ];

    initrd = {
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
      systemd.enable = true;
    };

    kernelPackages =
      config.boot.zfs.package.latestCompatibleLinuxPackages;
  };

  disko = {
    devices = {
      disk.main = {
        device = "/dev/disk/by-id/ata-SanDisk_SD8SBAT032G_153873411000";
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
                  # use zfs dataset

                  # "home" = {
                  #   mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                  #   mountpoint = "/home";
                  # };
                  # "nix" = {
                  #   mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                  #   mountpoint = "/nix";
                  # };
                  # "var" = {
                  #   mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nosuid" "nodev" ];
                  #   mountpoint = "/var";
                  # };
                };
              };
            };
          };
        };
      };
    };
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
