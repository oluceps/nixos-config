# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ inputs, config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "tpm" "tpm_tis" "tpm_crb" "kvm-amd" "amdgpu" ];
    };
    kernelModules = [ "ec_sys" "uhid" "kvm-amd" ];
    kernelParams = [
      "amd_pstate=active"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
    ];
    kernelPackages =
      # (import inputs.nixpkgs-pin {
      #   system = "x86_64-linux";
      # }).
      pkgs.linuxPackages_latest;
  };

  fileSystems."/" =
    {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ];
    };


  fileSystems."/persist" =
    {
      device = "/dev/disk/by-uuid/3a718c71-9404-45ea-8435-2fbd31f46d53";
      fsType = "btrfs";
      options = [ "subvolid=256" "compress-force=zstd" "noatime" "discard=async" "space_cache=v2" ];
      neededForBoot = true;
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/3a718c71-9404-45ea-8435-2fbd31f46d53";
      fsType = "btrfs";
      options = [ "subvolid=257" "compress-force=zstd" "noatime" "discard=async" "space_cache=v2" ];
    };


  fileSystems."/efi" =
    {
      device = "/dev/disk/by-uuid/CD6D-D5D1";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/1bbdbdd0-3527-4de2-95c4-3bc316c90968"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  # hardware.video.hidpi.enable = lib.mkDefault true;
}
