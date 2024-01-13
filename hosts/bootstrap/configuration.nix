{ config
, lib
, data
, inputs
, ...
}: {
  imports = [ "${inputs.nixpkgs}/nixos/modules/profiles/headless.nix" ];

  time.timeZone = "America/Los_Angeles";

  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = data.keys.hashedPasswd;
    openssh.authorizedKeys.keys = [
      data.keys.sshPubKey
      data.keys.skSshPubKey
    ];
  };

  systemd.network.enable = true;
  services.resolved.enable = false;

  systemd.network.networks.eth0 = {
    matchConfig.Name = "eth0";
    DHCP = "yes";
  };

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

  boot = {
    kernelParams = [
      "audit=0"
      "net.ifnames=0"

      "console=ttyS0"
      "earlyprintk=ttyS0"
      "rootdelay=300"
      "panic=1"
      "boot.panic_on_fail"
    ];
    loader = {
      grub = {
        enable = true;
        devices = "/dev/sda";
      };
      timeout = 1;
    };
    initrd = {
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
      systemd.enable = true;

      kernelModules = [
        "hv_vmbus"
        "hv_netvsc"
        "hv_utils"
        "hv_storvsc"

        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
      ];

      postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
        hwclock -s
      '';

      availableKernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"
      ];
    };
  };


  services.udev.extraRules = ''
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:0", ATTR{removable}=="0", SYMLINK+="disk/by-lun/0",
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:1", ATTR{removable}=="0", SYMLINK+="disk/by-lun/1",
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:2", ATTR{removable}=="0", SYMLINK+="disk/by-lun/2"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:3", ATTR{removable}=="0", SYMLINK+="disk/by-lun/3"

    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:4", ATTR{removable}=="0", SYMLINK+="disk/by-lun/4"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:5", ATTR{removable}=="0", SYMLINK+="disk/by-lun/5"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:6", ATTR{removable}=="0", SYMLINK+="disk/by-lun/6"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:7", ATTR{removable}=="0", SYMLINK+="disk/by-lun/7"

    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:8", ATTR{removable}=="0", SYMLINK+="disk/by-lun/8"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:9", ATTR{removable}=="0", SYMLINK+="disk/by-lun/9"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:10", ATTR{removable}=="0", SYMLINK+="disk/by-lun/10"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:11", ATTR{removable}=="0", SYMLINK+="disk/by-lun/11"

    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:12", ATTR{removable}=="0", SYMLINK+="disk/by-lun/12"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:13", ATTR{removable}=="0", SYMLINK+="disk/by-lun/13"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:14", ATTR{removable}=="0", SYMLINK+="disk/by-lun/14"
    ENV{DEVTYPE}=="disk", KERNEL!="sda" SUBSYSTEM=="block", SUBSYSTEMS=="scsi", KERNELS=="?:0:0:15", ATTR{removable}=="0", SYMLINK+="disk/by-lun/15"

  '';

}
