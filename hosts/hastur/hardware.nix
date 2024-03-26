# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config
, lib
, pkgs
, modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/persist" ];
  };

  boot = {
    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };

    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "zsmalloc" ];
      kernelModules = [ "tpm" "tpm_tis" "tpm_crb" "kvm-amd" ];
    };
    kernelModules = [ "ec_sys" "uhid" "kvm-amd" ];
    # extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    kernelPackages =
      pkgs.linuxPackages_latest;
    # inputs.nyx.packages.${pkgs.system}.linuxPackages_cachyos-lto-zen3;
    # binfmt.emulatedSystems = [
    #   "riscv64-linux"
    #   "aarch64-linux"
    #   "mips64el-linux"
    #   "mipsel-linux"
    # ];
    kernelParams = [
      "amd_pstate=active"
      "amd_iommu=on"
      "random.trust_cpu=off"
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.zpool=zsmalloc"
      "systemd.gpt_auto=0"
    ];
  };


  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-HP_SSD_FX900_Plus_M.2_2TB_HBSE53120600733";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
              };
            };
            root = {
              end = "-32G";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "--csum xxhash64" "--label nixos" ]; # Override existing partition
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

            plainSwap = {
              size = "100%";
              content = {
                type = "swap";
                resumeDevice = true;
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


  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
