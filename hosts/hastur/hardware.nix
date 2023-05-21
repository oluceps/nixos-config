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

  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "tpm" "tpm_tis" "tpm_crb" "kvm-amd" ];
    };
    kernelModules = [ "ec_sys" "uhid" "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    binfmt.emulatedSystems = [
      "riscv64-linux"
      "aarch64-linux"
      "mips64el-linux"
      "mipsel-linux"
    ];
    kernelParams = [
      "mitigations=off"
    ];
    resumeDevice = "/dev/disk/by-uuid/5ddc05a2-22a7-4803-8bca-fc64fad0b478";
  };


  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/e86a6cfa-39cc-4dd9-b5d3-fee5e2613578";
    fsType = "btrfs";
    options = [ "subvolid=256" "compress-force=zstd" "noatime" "discard=async" "space_cache=v2" ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/e86a6cfa-39cc-4dd9-b5d3-fee5e2613578";
    fsType = "btrfs";
    options = [ "subvolid=258" "compress-force=zstd" "noatime" "discard=async" "space_cache=v2" ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/F680-4A3F";
    fsType = "vfat";
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/5ddc05a2-22a7-4803-8bca-fc64fad0b478"; }];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
