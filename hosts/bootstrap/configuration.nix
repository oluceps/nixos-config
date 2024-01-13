{ config
, lib
, data
, ...
}: {
  boot.kernelParams = [
    "audit=0"
    "net.ifnames=0"
  ];

  boot.initrd = {
    compressor = "zstd";
    compressorArgs = [ "-19" "-T0" ];
    systemd.enable = true;
  };

  boot.loader.grub = {
    enable = !config.boot.isContainer;
    default = "saved";
    devices = [ "/dev/vda" ];
  };

  time.timeZone = "America/Los_Angeles";

  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = data.keys.hashedPasswd;
    openssh.authorizedKeys.keys = [
      data.keys.sshPubKey
      data.keys.sKSshPubKey
    ];
  };

  systemd.network.enable = true;
  services.resolved.enable = false;

  systemd.network.networks.eth0 = {
    matchConfig.Name = "eth0";
    DHCP = "yes";
  };

  networking.nameservers = [
    "8.8.8.8"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };

  networking.firewall.enable = false;

  networking.useDHCP = false;

  networking.hostName = "bootstrap";

  system.stateVersion = "23.05";

  boot.initrd.postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
    hwclock -s
  '';

  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
  ];
  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];
}
