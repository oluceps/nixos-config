{ config, pkgs, lib, ... }:

{

  zramSwap = {
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };
  boot = {
    tmp.cleanOnBoot = true;
    loader.grub = {
      enable = true;
      # devices = [ "/dev/vda" ]; disko auto add
    };

    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
    initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" "nvme" ];

    initrd.postDeviceCommands = pkgs.lib.mkIf (!config.boot.initrd.systemd.enable)
      ''
        # Set the system time from the hardware clock to work around a
        # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
        # to the *boot time* of the host).
        hwclock -s
      '';

    kernelParams = [
      "audit=0"
      "net.ifnames=0"
    ];

    initrd = {
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
      systemd.enable = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              type = "EF02";
              label = "BOOT";
              start = "0";
              end = "+1M";
            };

            ESP = {
              size = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "--csum xxhash64"
                  "--label nixos"
                  "--features"
                  "block-group-tree"
                ]; # Override existing partition
                subvolumes = {
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" "nodev" "nosuid" ];
                  };
                  "/var" = {
                    mountpoint = "/var";
                    mountOptions = [ "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" ];
                  };
                  "/persist/tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [ "relatime" "nodev" "nosuid" "discard=async" "space_cache=v2" ];
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [ "relatime" "nosuid" "nodev" "size=2G" "mode=755" ];
      };
    };
  };

  fileSystems."/persist".neededForBoot = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
