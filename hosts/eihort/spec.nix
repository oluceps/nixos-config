{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    dockerCompat = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };
  systemd.services.mount-three = {
    description = "mount pool 3";
    script =
      let
        diskId = map (n: "/dev/disk/by-id/" + n) [
          "nvme-INTEL_MEMPEK1J016GAH_PHBT82920C53016N"
          "wwn-0x5000cca05838bc98"
          "wwn-0x5000cca0583a5e34"
          "wwn-0x5000cca04608e534"
          "wwn-0x5000cca0583880c4"
        ];
      in
      ''
        /run/current-system/sw/bin/mount -o noatime,nodev,nosuid \
        -t bcachefs \
        ${lib.concatStringsSep ":" diskId} \
        /three
      '';
    wantedBy = [ "multi-user.target" ];
  };

  boot = {
    supportedFilesystems = [ "tcp_bbr" ];
    inherit ((import ../../boot.nix { inherit lib; }).boot) kernel;
  };
  environment.systemPackages = with pkgs;[ zfs ];

  services = lib.mkMerge [
    {
      inherit ((import ../../services.nix
        (lib.base
          // { inherit pkgs config; })).services)
        openssh fail2ban mosdns dae;
      resolved.enable = lib.mkForce false;

    }
    {
      zfs.autoScrub.enable = true;
      dae.enable = true;
      mosdns.enable = true;

      # compose-up.instances = [
      #   {
      #     name = "misskey";
      #     workingDirectory = "/home/${user}/Src/misskey";
      #   }
      # ];

      hysteria.instances = [{
        name = "nodens";
        configFile = config.age.secrets.hyst-us-cli-has.path;
      }
        {
          name = "colour";
          configFile = config.age.secrets.hyst-az-cli-has.path;
        }];

      shadowsocks.instances = [
        {
          name = "rha";
          configFile = config.age.secrets.ss-az.path;
          serve = {
            enable = true;
            port = 6059;
          };
        }
      ];

    }
  ];

  programs = {
    git.enable = true;
    fish.enable = true;
  };

  systemd = {
    enableEmergencyMode = true;
    watchdog = {
      # systemd will send a signal to the hardware watchdog at half
      # the interval defined here, so every 10s.
      # If the hardware watchdog does not get a signal for 20s,
      # it will forcefully reboot the system.
      runtimeTime = "20s";
      # Forcefully reboot if the final stage of the reboot
      # hangs without progress for more than 30s.
      # For more info, see:
      #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
      rebootTime = "30s";
    };

  };

  systemd.tmpfiles.rules = [
  ];

  system.stateVersion = "24.05"; # Did you read the comment?

}