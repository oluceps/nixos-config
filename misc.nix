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
    enable = false;
    algorithm = "zstd";
  };


  age.secrets = {

    ssconf = {
      file = ./secrets/ssconf.age;
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

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';
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
    dconf.enable = true;
  };
  #  programs.waybar.enable = true;
  #
  #  # Enable the GNOME Desktop Environment.
  #  services.xserver.desktopManager.gnome.enable = false;
  #  services.xserver.videoDrivers = ["nvidia"];
  #  hardware.opengl.enable=true;
  #  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
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
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      sarasa-gothic
      twemoji-color-font
      #      font-awesome
      #      fira-code-symbols
      #    cascadia-code
    ] ++ (with (pkgs.callPackage ./modules/packs/glowsans/default.nix { }); [ glowsansSC glowsansTC glowsansJ ])
    ++ (with nur-pkgs;[ maple-font.Mono-NF-v5 san-francisco plangothic ]);
    #"HarmonyOS Sans SC" "HarmonyOS Sans TC"
    fontconfig = {
      defaultFonts = {
        serif = [ "Glow Sans SC" "Glow Sans TC" "Glow Sans J" "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" ];
        monospace = [ "SF Mono" ];
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
    ];
  };
  #    enabled = "ibus";
  #    ibus.engines = with pkgs.ibus-engines; [
  #      libpinyin
  #      rime
  #    ];
  system.stateVersion = "22.11"; # Did you read the comment?
}
