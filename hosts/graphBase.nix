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
    git.enable = true;
    bash = {
      interactiveShellInit = ''
        eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
        eval "$(${lib.getExe pkgs.atuin} init bash)"
      '';
      blesh.enable = true;
    };
    kdeconnect.enable = true;
    adb.enable = true;
    mosh.enable = true;
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

  services.xserver = {
    enable = lib.mkDefault false;
    xkb.layout = "us";
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
