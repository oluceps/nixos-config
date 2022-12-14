# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config
, pkgs
, lib
, user
, ...
}: {
  nixpkgs.config.allowUnfree = true;

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
    waydroid.enable = true;
  };
  qt5 = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };
  services.xserver =
    {
      enable = false;
      layout = "us";
      xkbOptions = "eurosign:e";
      windowManager.bspwm.enable = true;

      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };


  age.identityPaths = [ "/persist/keys/ssh_host_ed25519_key" ];
  age.secrets = {

    ss = {
      file = ./secrets/ss.age;
      mode = "770";
      owner = user;
      group = user;
    };

    sing = {
      file = ./secrets/sing.age;
      mode = "770";
      owner = user;
      group = user;
    };

    hyst = {
      file = ./secrets/hyst.age;
      mode = "770";
      owner = user;
      group = user;
    };

    tuic = {
      file = ./secrets/tuic.age;
      mode = "770";
      owner = user;
      group = user;
    };
    naive = {
      file = ./secrets/naive.age;
      mode = "770";
      owner = user;
      group = user;
    };




  };
  nix = {
    #     settings.substituters = [ "https://mirrors.bfsu.edu.cn/nix-channels/store" ];
    package = pkgs.nixVersions.stable;

    settings = {

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nur-pkgs.cachix.org-1:PAvPHVwmEBklQPwyNZfy4VQqQjzVIaFOkYYnmnKco78="
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nur-pkgs.cachix.org"
      ];
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "riro" "elena" ];
    };
  };

  environment = {
    shellInit = ''
      export GPG_TTY="$(tty)"
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
    '';
    loginShellInit = "";
    #      if user == "riro" then
    #        ''
    #          autossh -M 5678 -fNTR 5002:127.0.0.1:22 oc > /dev/null
    #          autossh -M 5678 -fNTR 5002:127.0.0.1:22 az > /dev/null
    #        '' else
    #        ''
    #          autossh -M 5678 -fNTR 5003:127.0.0.1:22 oc > /dev/null
    #          autossh -M 5678 -fNTR 5003:127.0.0.1:22 az > /dev/null
    #        '';


  };
  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  programs = {
    fish.enable = true;
    sway.enable = true;
    kdeconnect.enable = true;
    dconf.enable = true;
    adb.enable = true;
    mosh.enable = true;
    nix-ld.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

  };
  #  programs.waybar.enable = true;
  #
  #  # Enable the GNOME Desktop Environment.
  #  services.xserver.desktopManager.gnome.enable = false;
  services.xserver.screenSection = ''
    Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option         "AllowIndirectGLXProtocol" "off"
    Option         "TripleBuffer" "on"
  '';
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.powerManagement.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
  };
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [

      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "DroidSansMono"
          "JetBrainsMono"
          "FantasqueSansMono"
        ];
      })
      source-han-sans
      fantasque-sans-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      sarasa-gothic
      twemoji-color-font
      #      font-awesome
      #      fira-code-symbols
      #    cascadia-code
    ]
    ++ (with (pkgs.callPackage ./modules/packs/glowsans/default.nix { }); [ glowsansSC glowsansTC glowsansJ ])
    ++ (with nur-pkgs;[ maple-font.Mono-NF-v5 san-francisco plangothic maoken-tangyuan ]);
    #"HarmonyOS Sans SC" "HarmonyOS Sans TC"
    fontconfig = {
      subpixel.rgba = "none";
      defaultFonts = {
        serif = [ "Glow Sans SC" "Glow Sans TC" "Glow Sans J" "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" ];
        monospace = [ "SF Mono" "Fantasque Sans Mono" ];
        sansSerif = [ "Glow Sans SC" "Glow Sans TC" "Glow Sans J" "SF Pro Text" ];
        emoji = [ "twemoji-color-font" "noto-fonts-emoji" ];
      };
    };
  };
  # Enable sound.
  security.rtkit.enable = true;

  # $ nix search wget
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chinese-addons
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-configtool
      fcitx5-pinyin-zhwiki
    ];
  };
  #    enabled = "ibus";
  #    ibus.engines = with pkgs.ibus-engines; [
  #      libpinyin
  #      rime
  #    ];
  system.stateVersion = "22.11"; # Did you read the comment?
}
