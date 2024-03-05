{ pkgs
, lib
, config
, ...
}:

{
  systemd.services.btrfs-scrub-persist.serviceConfig.ExecStopPost =
    lib.genNtfyMsgScriptPath "tags red_circle prio high" "error" "btrfs scrub failed on hastur";

  systemd.user.services.nix-index = {
    environment = config.networking.proxy.envVars;
    script = ''
      FILE=index-x86_64-linux
      mkdir -p ~/.cache/nix-index
      cd ~/.cache/nix-index
      ${pkgs.curl}/bin/curl -LO https://github.com/Mic92/nix-index-database/releases/latest/download/$FILE
      mv -v $FILE files
    '';
    serviceConfig = {
      Restart = "on-failure";
      Type = "oneshot";
    };
    startAt = "weekly";
  };

  services = {
    bpftune.enable = true;
    kubo = {
      enable = false;
      settings.Addresses.API = [
        "/ip4/127.0.0.1/tcp/5001"
      ];
    };
    i2pd = {
      enable = false;
      notransit = true;
      outTunnels = {
        # ssh-vpqn = {
        #   enable = true;
        #   name = "ssh";
        #   destination = "";
        #   address = "127.0.0.1";
        #   port = 2222;
        # };
      };
    };

    fwupd.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
      apparmor = "enabled";
    };

    flatpak.enable = true;
    journald.extraConfig =
      ''
        SystemMaxUse=1G
      '';
    # sundial = {
    #   enable = false;
    #   calendars = [ "Sun,Mon-Thu 23:18:00" "Fri,Sat 23:48:00" ];
    #   warnAt = [ "Sun,Mon-Thu 23:16:00" "Fri,Sat 23:46:00" ];
    # };

    udev = {
      packages = with pkgs;[
        android-udev-rules
        # qmk-udev-rules
        jlink-udev-rules
        yubikey-personalization
        libu2f-host
        via
        opensk-udev-rules
        nrf-udev-rules
      ];
    };

    gnome.gnome-keyring.enable = true;

    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/persist" ];
    };

    pcscd.enable = true;

  };
}
