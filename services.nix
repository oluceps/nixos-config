{ pkgs
, lib
, user
, ...
}:

{
  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable the OpenSSH daemon.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };


  systemd = {
    # Given that our systems are headless, emergency mode is useless.
    # We prefer the system to attempt to continue booting so
    # that we can hopefully still access it remotely.
    enableEmergencyMode = false;

    # For more detail, see:
    #   https://0pointer.de/blog/projects/watchdog.html
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

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  services = {
    # github-runners = {
    #   runner1 = {
    #     enable = false;
    #     name = "nixos-0";
    #     tokenFile = config.age.secrets.gh-eu.path;
    #     url = "https://github.com/oluceps/eunomia-bpf";
    #   };
    # };
    autossh.sessions = [
      {
        extraArguments = "-NTR 5002:127.0.0.1:22 az";
        monitoringPort = 20000;
        name = "az";
        inherit user;
      }
    ];
    flatpak.enable = true;
    journald.extraConfig =
      ''
        SystemMaxUse=1G
      '';
    sundial = {
      enable = true;
      calendars = [ "Sun,Mon-Thu 23:18:00" "Fri,Sat 23:48:00" ];
      warnAt = [ "Sun,Mon-Thu 23:16:00" "Fri,Sat 23:46:00" ];
    };

    # HORRIBLE
    # mongodb = {
    #   enable = true;
    #   package = pkgs.mongodb-6_0;
    #   enableAuth = true;
    #   initialRootPassword = "initial";
    # };

    mysql = {
      enable = true;
      package = pkgs.mariadb_109;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command =
            "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.writeShellScript "Hyprland" ''
          export $(/run/current-system/systemd/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
          exec Hyprland
        ''}";
          user = "greeter";
        };

      };
    };

    udev = {

      packages = with pkgs;[
        android-udev-rules
        qmk-udev-rules
        yubikey-personalization
        libu2f-host
        via
        opensk-udev-rules
        nrf-udev-rules
      ];
    };

    gnome.gnome-keyring.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    hyst-az.enable = true;
    hyst-do.enable = true;
    hyst-am.enable = true;

    # ss-tls cnt to router
    ss.enable = false;
    tuic.enable = false;
    naive.enable = true;

    clash =
      {
        enable =
          false;
      };

    sing-box.enable = false;
    rathole.enable = true;

    dae.enable = true;

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/persist" "/nix" ];
    };
    pcscd.enable = true;

    openssh = {
      enable = true;
      settings = {
        passwordAuthentication = false;
        UseDns = false;
        X11Forwarding = false;
      };
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
      extraConfig = ''
        ClientAliveInterval 60
        ClientAliveCountMax 720
      '';
    };

    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
    };

    resolved = {
      enable = true;
      dnssec = "false";
      llmnr = "false";
      extraConfig = ''
        DNS=223.6.6.6#dns.alidns.com
        MulticastDNS=true
        DNSOverTLS=false
        DNSStubListener=yes
      '';
    };
  };

  programs = {
    ssh.startAgent = false;
    proxychains = {
      enable = true;

      chain = {
        type = "strict";
      };
      proxies = {
        clash = {
          type = "socks5";
          host = "127.0.0.1";
          port = 7890;
        };
      };
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

  };
}
