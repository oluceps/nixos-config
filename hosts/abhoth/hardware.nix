{
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd = {
    systemd.enable = true;
    compressor = "zstd";
    compressorArgs = [
      "-19"
      "-T0"
    ];
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "audit=0"
    "net.ifnames=0"

    "console=ttyS0"
    "earlyprintk=ttyS0"
    "rootdelay=300"
  ];
  fileSystems."/" = {
    device = "/dev/vda2";
    fsType = "ext4";
  };

  kernelModules = [ "brutal" ];
  extraModulePackages = with config.boot.kernelPackages; [
    (callPackage "${inputs.self}/pkgs/tcp-brutal.nix" { })
  ];
}
