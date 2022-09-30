{ config
, pkgs
, lib
, ...
}:

let user = "riro"; in
{
  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable the OpenSSH daemon.

  security.pam.u2f.enable = true;
  services = {
    udev.packages = [ pkgs.android-udev-rules pkgs.qmk-udev-rules (pkgs.callPackage ./modules/packs/opensk-udev-rules { }) ];
    gnome.gnome-keyring.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    #    hysteria.enable = true;


    ss = {
      enable = true;
    };
    hysteria.enable = false;
    clash =
      {
        enable =
          if
            (lib.lists.last (import ./hosts/hastur/network.nix { inherit config pkgs; }).systemd.network.networks."20-wired".routes).routeConfig.Gateway != "192.168.2.2"
          # Switch depend on the Gateway before. Always false now
          then false
          else false;
      };

    sing-box = {
      enable = true;
    };



    snapper = {
      snapshotRootOnBoot = true;
      snapshotInterval = "hourly";
      cleanupInterval = "3d";
      configs = {

        root = {
          subvolume = "/";
          extraConfig = ''
            ALLOW_USERS="${user}"
            TIMELINE_CREATE=yes
            TIMELINE_CLEANUP=yes
          '';
        };

        home = {
          subvolume = "/home";
          extraConfig = ''
            ALLOW_USERS="${user}"
            TIMELINE_CREATE=yes
            TIMELINE_CLEANUP=yes
          '';
        };

        nix = {
          subvolume = "/nix";
          extraConfig = ''
            ALLOW_USERS="${user}"
            TIMELINE_CREATE=yes
            TIMELINE_CLEANUP=yes
          '';
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
      extraConfig = ''
        useDNS no
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
      dnssec = "allow-downgrade";
      extraConfig = ''
        DNS=223.6.6.6 101.6.6.6:5353 202.141.178.13:5353
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

    tmux = {
      aggressiveResize = true;
      clock24 = true;
      enable = true;
      newSession = true;
      reverseSplit = true;

      plugins = with pkgs.tmuxPlugins; [
        prefix-highlight
        nord
      ];
    };
  };
}
