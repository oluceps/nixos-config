# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/persist" ];
  };
  # hardware.tuxedo-rs = {
  #   enable = true;
  #   tailor-gui.enable = true;
  # };

  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
  };
  boot = {
    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };

    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
    };
    kernelModules = [ "kvm-amd" ];
    # extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    kernelPackages =
      # pkgs.linuxPackages_latest;
      inputs.nyx.packages.${pkgs.system}.linuxPackages_cachyos;
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
      "ia32_emulation=0"
    ];
  };

  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WDS100T3X0C-00SJG0_21191G463913";
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

            cryptroot = {
              label = "CRYPTROOT";
              end = "-32G";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                  crypttabExtraOpts = [
                    "same-cpu-crypt"
                    "submit-from-crypt-cpus"
                    "fido2-device=auto"
                  ];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "--label nixos"
                    "-f"
                    "--csum xxhash64"
                    "--features"
                    "block-group-tree"
                  ];
                  subvolumes = {
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress-force=lzo"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress-force=lzo"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                        "nodev"
                        "nosuid"
                      ];
                    };
                    "/var" = {
                      mountpoint = "/var";
                      mountOptions = [
                        "compress-force=lzo"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };
                    "/persist/tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [
                        "relatime"
                        "nodev"
                        "nosuid"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };
                  };
                };
              };
            };
            encryptedSwap = {
              end = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "relatime"
          "nosuid"
          "nodev"
          "size=2G"
          "mode=755"
        ];
      };
    };
  };

  fileSystems."/persist".neededForBoot = true;
  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
    # gcc.arch = "znver3";
    # gcc.tune = "znver3";
  };

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
