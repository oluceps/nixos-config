{ inputs, pkgs, config, lib, ... }:
{
  # server inside the cage.

  system.stateVersion = "23.05";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  boot = {
    supportedFilesystems = [ "tcp_bbr" ];
    inherit ((import ../../boot.nix { inherit lib; }).boot) kernel;
  };

  services = {
    inherit ((import ../../services.nix { inherit pkgs lib config inputs; }).services) openssh;
  };

  programs = {
    git.enable = true;
    fish.enable = true;
  };
  zramSwap = {
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  systemd = {
    enableEmergencyMode = false;
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
  services = {
    dae = {
      enable = true;
      package = pkgs.dae-unstable;
      disableTxChecksumIpGeneric = false;
      configFile = config.age.secrets.dae.path;
      assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
      openFirewall = {
        enable = true;
        port = 12345;
      };
    };
  };
}
