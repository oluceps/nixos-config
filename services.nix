{ config
, pkgs
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

  security.pam.u2f.enable = true;
  xdg.portal.enable = true;

  services = {
    flatpak.enable = true;
    journald.extraConfig =
      ''
        SystemMaxUse=1G
      '';
    udev = {

      packages = with pkgs;[
        android-udev-rules
        qmk-udev-rules
        yubikey-personalization
        libu2f-host
        via
      ] ++
      [ (pkgs.callPackage ./modules/packs/opensk-udev-rules { }) ];

      #      extraRules = ''
      #        ACTION=="add|remove", SUBSYSTEM=="net", ATTR{idVendor}=="22d9" ENV{ID_USB_DRIVER}=="rndis_host", SYMLINK+="android", RUN+="systemctl restart systemd-networkd.service"
      #      '';
    };

    gnome.gnome-keyring.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    #    hysteria.enable = true;


    ss.enable = false;

    hysteria.enable = false;

    tuic.enable = false;

    naive.enable = true;

    clash =
      {
        enable =
          if
            true
          #            (lib.lists.last (import ./hosts/hastur/network.nix { inherit config pkgs; }).systemd.network.networks."20-wired".routes).routeConfig.Gateway != "192.168.2.2"
          # switch depend on the Gateway. Always false now
          then false
          else false;
      };

    sing-box = {
      enable = true;
    };

    btrbk = {
      instances = {
        base = {
          onCalendar = "*:0/20"; # every quarter hour
          settings = {
            timestamp_format = "long";
            snapshot_preserve_min = "18h";
            snapshot_preserve = "72h";
            volume = {
              "/" = {
                snapshot_dir = ".snapshots";
                subvolume = {
                  "." = { snapshot_create = "always"; };
                  home = { snapshot_create = "always"; };
                  nix = { snapshot_create = "always"; };
                };
              };
            };

          };
        };
      };
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/home" "/nix" ];
    };
    pcscd.enable = true;

    openssh = {
      enable = true;
      passwordAuthentication = false;
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
      dnssec = "allow-downgrade";
      extraConfig = ''
        DNS=223.6.6.6 202.141.178.13:5353
                  #223.6.6.6 101.6.6.6:5353 202.141.178.13:5353
        Domains=~.
        MulticastDNS=true
        DNSSEC=off
        DNSStubListener = false
        DNSOverTLS = false
      '';
      fallbackDns = [
        "101.6.6.6:5353"
        "211.138.151.161"
        "8.8.4.4"
        "1.1.1.1"
      ];

      llmnr = "true";
    };
  };


  qt5.platformTheme = "qt5ct";

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
