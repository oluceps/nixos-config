# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  data,
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{

  hardware.pulseaudio.enable = lib.mkForce false;
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [
      "/persist"
      "/three"
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
            esp = {
              label = "ESP";
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
              size = "1024G";
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
              size = "16G";
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

  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  security.tpm2.tctiEnvironment.enable = true;

  services.scx = {
    enable = false;
    scheduler = "scx_lavd";
  };
  boot = {
    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };

    supportedFilesystems = [
      "bcachefs"
      "ntfs"
    ];
    initrd = {
      systemd = {
        enable = true;
        # emergencyAccess = data.keys.hashedPasswd;
        # work with cachyos kernel
        # suppressedStorePaths = [
        #   "${config.boot.initrd.systemd.package}/lib/systemd/system-generators/systemd-hibernate-resume-generator"
        # ];
      };
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "lz4"
        "zsmalloc"
        "xhci_hcd"
      ];
      kernelModules = [
        "tpm"
        "tpm_tis"
        "tpm_crb"
        "kvm-amd"
        "amdgpu"
        "xhci_pci"
        "usbhid"
        "xhci_hcd"
        "atkbd"
      ];
    };
    kernelModules = [
      "ec_sys"
      "uhid"
      "kvm-amd"
      "brutal"
      "dm_sflc"
    ];
    kernelParams = [
      "amd_pstate=active"
      "zswap.enabled=1"
      "zswap.zpool=zsmalloc"
      "systemd.gpt_auto=0"
      "noresume"
      "acpi_os_name=\"Microsoft Windows NT\""
    ];
    extraModulePackages =
      let
        inherit (config.boot.kernelPackages) v4l2loopback callPackage;
      in
      [
        v4l2loopback
        (callPackage "${inputs.self}/pkgs/tcp-brutal.nix" { })
      ];
    kernelPackages =
      # (import inputs.nixpkgs-pin {
      #   system = "x86_64-linux";
      # })
      pkgs.linuxPackages_latest;
    # inputs.nyx.packages.${pkgs.system}.linuxPackages_cachyos-zen3;

    # kernelPatches =
    #   let patchPath = ../../.attachs/cachyos-kernel;
    #   in map (name: { inherit name; patch = patchPath + ("/" + name); })
    #     (with builtins;attrNames (readDir patchPath));
  };

  # fileSystems."/" =
  #   {
  #     device = "none";
  #     fsType = "tmpfs";
  #     options = [ "defaults" "size=2G" "mode=755" ];
  #   };

  # fileSystems."/persist" =
  #   {
  #     device = "/dev/disk/by-uuid/3a718c71-9404-45ea-8435-2fbd31f46d53";
  #     fsType = "btrfs";
  #     options = [ "subvol=/persist" "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" ];
  #     neededForBoot = true;
  #   };

  # fileSystems."/nix" =
  #   {
  #     device = "/dev/disk/by-uuid/3a718c71-9404-45ea-8435-2fbd31f46d53";
  #     fsType = "btrfs";
  #     options = [ "subvol=/nix" "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" ];
  #   };

  # fileSystems."/nix/var" =
  #   {
  #     device = "/dev/disk/by-uuid/a3df5e05-7a19-4734-89d7-c9bcfd4c2d70";
  #     fsType = "xfs";
  #     options = [ "noatime" ];
  #   };

  # fileSystems."/var" =
  #   {
  #     device = "/dev/disk/by-uuid/3a718c71-9404-45ea-8435-2fbd31f46d53";
  #     fsType = "btrfs";
  #     options = [ "subvol=/var" "compress-force=zstd:1" "noatime" "discard=async" "space_cache=v2" ];
  #   };

  # fileSystems."/tmp" = {
  #   device = "/dev/disk/by-uuid/3a718c71-9404-45ea-8435-2fbd31f46d53";
  #   fsType = "btrfs";
  #   options = [ "subvol=/tmp" "noatime" "discard=async" "space_cache=v2" ];
  # };

  # fileSystems."/efi" =
  #   {
  #     device = "/dev/disk/by-partuuid/fe3e996f-7962-1f4b-8bac-e2c8bc420501";
  #     fsType = "vfat";
  #   };

  # swapDevices =
  #   [{ device = "/dev/disk/by-uuid/1bbdbdd0-3527-4de2-95c4-3bc316c90968"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };

  # high-resolution display
  # hardware.video.hidpi.enable = lib.mkDefault true;
}
