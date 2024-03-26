{ config, pkgs, lib, inputs, user, ... }:
{
  xdg = {
    mime = {
      enable = true;
      inherit ((import ../home/home.nix { inherit config pkgs lib inputs user; }).xdg.mimeApps) defaultApplications;
    };
  };

  virtualisation = {
    libvirtd = {
      enable = false;
      qemu.ovmf = {
        enable = true;
        packages =
          # let
          #   pkgs = import inputs.nixpkgs-22 {
          #     system = "x86_64-linux";
          #   };
          # in
          [
            pkgs.OVMFFull.fd
            pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd
          ];
      };
      qemu.swtpm.enable = true;

    };
    waydroid.enable = false;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita";
  };
  programs = {

    wireshark = { enable = true; package = pkgs.wireshark; };
    kdeconnect.enable = true;
    adb.enable = true;
    command-not-found.enable = false;
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs: [ pkgs.maple-mono-SC-NF ];
      };
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    gnupg = {
      agent = {
        enable = false;
        pinentryPackage = pkgs.pinentry-curses;
        enableSSHSupport = true;
      };
    };
  };
  security = {
    pam.services.swaylock = { };
    # Enable sound.
    rtkit.enable = true;
  };
  services = {

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
    dbus = {
      enable = true;
      implementation = "broker";
      apparmor = "enabled";
    };
    fwupd.enable = true;

    flatpak.enable = true;
    pcscd.enable = true;
    xserver = {
      enable = lib.mkDefault false;
      xkb.layout = "us";
    };
  };



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


  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = false;
    enableGhostscriptFonts = false;
    packages = with pkgs; [

      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "JetBrainsMono"
          "FantasqueSansMono"
        ];
      })
      source-han-sans
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      twemoji-color-font
      maple-mono-SC-NF
      maple-mono-otf
      maple-mono-autohint
      cascadia-code
      intel-one-mono
      monaspace
    ]
    ++ (with pkgs.glowsans; [ glowsansSC glowsansTC glowsansJ ])
    ++ (with nur-pkgs; [ san-francisco plangothic maoken-tangyuan lxgw-neo-xihei ]);
    #"HarmonyOS Sans SC" "HarmonyOS Sans TC"
    fontconfig = {
      subpixel.rgba = "none";
      antialias = true;
      hinting.enable = false;
      defaultFonts = lib.mkForce {
        serif = [ "Glow Sans SC" "Glow Sans TC" "Glow Sans J" "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" ];
        monospace = [ "Monaspace Neon" "Maple Mono" "SF Mono" "Fantasque Sans Mono" ];
        sansSerif = [ "Hanken Grotesk" "Glow Sans SC" ];
        emoji = [ "twemoji-color-font" "noto-fonts-emoji" ];
      };
    };
  };

  # $ nix search wget
  i18n = {

    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-configtool
        fcitx5-pinyin-zhwiki
        fcitx5-pinyin-moegirl
      ];
    };
  };

}
