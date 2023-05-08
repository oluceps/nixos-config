# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ inputs
, config
, pkgs
, lib
, user
, data
, ...
}: {
  systemd.tmpfiles.rules = [
    "C /var/cache/tuigreet/lastuser - - - - ${pkgs.writeText "lastuser" "${user}"}"
  ];


  rekey = {
    extraEncryptionPubkeys = [ data.keys.ageKey ];
    masterIdentities = [ ./secrets/age-yubikey-identity-7d5d5540.txt.pub ];

    secrets =
      let
        genSec = ns: owner: group: lib.genAttrs ns (n: { file = ./secrets/${n}.age; mode = "770"; inherit owner group; });
      in
      (genSec [ "rat" "ss" "sing" "hyst-az" "hyst-am" "hyst-do" "tuic" "naive" "wg" ] "proxy" "users") //
      (genSec [ "ssh" "gh-eu" "u2f" "gh-token" ] user "nogroup") //
      {
        dae = { file = ./secrets/dae.age; mode = "640"; owner = "proxy"; group = "users"; name = "d.dae"; };
      };

  };


  xdg = {
    mime = {
      enable = true;
      defaultApplications = {
        "tg" = [ "telegramdesktop.desktop" ];

        "application/pdf" = [ "sioyek.desktop" ];
        "ppt/pptx" = [ "wps-office-wpp.desktop" ];
        "doc/docx" = [ "wps-office-wps.desktop" ];
        "xls/xlsx" = [ "wps-office-et.desktop" ];
      }
      //
      lib.genAttrs [
        "x-scheme-handler/unknown"
        "x-scheme-handler/about"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "text/html"
      ]
        (_: "google-chrome.desktop")
      //
      lib.genAttrs [
        "image/gif"
        "image/webp"
        "image/png"
        "image/jpeg"
      ]
        (_: "org.gnome.eog.desktop")
      ;
    };
  };

  networking.firewall.trustedInterfaces = [ "virbr0" ];
  virtualisation = {
    docker.enable = true;
    libvirtd = {
      enable = false;
      qemu = {
        ovmf = {
          enable = true;
          packages =
            let
              pkgs = import inputs.nixpkgs-22 {
                system = "x86_64-linux";
              };
            in
            [
              pkgs.OVMFFull.fd
              pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd
            ];
        };
        swtpm.enable = true;
      };
    };
    waydroid.enable = false;
  };
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };
  zramSwap = {
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  nix =
    {
      package = pkgs.nixVersions.stable;

      settings = {

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
          "nur-pkgs.cachix.org-1:PAvPHVwmEBklQPwyNZfy4VQqQjzVIaFOkYYnmnKco78="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        ];
        substituters = (map (n: "https://${n}.cachix.org")
          [ "nix-community" "nur-pkgs" "hyprland" "helix" ])
        ++
        [
          "https://cache.nixos.org"
          "https://cache.ngi0.nixos.org"
        ];
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
          "auto-allocate-uids"
          "cgroups"
          "repl-flake"
          "recursive-nix"
          "ca-derivations"
        ];
        auto-allocate-uids = true;
        use-cgroups = true;

        trusted-users = [ "root" "${user}" ];
        # Avoid disk full
        max-free = lib.mkDefault (1000 * 1000 * 1000);
        min-free = lib.mkDefault (128 * 1000 * 1000);
        builders-use-substitutes = true;
      };

      daemonCPUSchedPolicy = lib.mkDefault "batch";
      daemonIOSchedClass = lib.mkDefault "idle";
      daemonIOSchedPriority = lib.mkDefault 7;


      extraOptions = ''
        keep-outputs = true
        keep-derivations = true
        # access-tokens = github.com=@${config.rekey.secrets.gh-token.path}
      '';
    };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  console = {
    font = "LatArCyrHeb-16";
    keyMap = "us";
  };

  programs = {
    starship = {
      enable = true;
      settings = (import ./home/programs/starship { }).programs.starship.settings // {
        format = "$username$directory$git_branch$git_commit$git_status$nix_shell$cmd_duration$line_break$python$character";
      };
    };
    neovim = {
      enable = false;
      configure = {
        customRC = ''set number'';
      };
    };
    git.enable = true;
    fish.enable = true;
    sway.enable = true;
    kdeconnect.enable = true;
    dconf.enable = true;
    adb.enable = true;
    mosh.enable = true;
    nix-ld.enable = true;
    command-not-found.enable = false;
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    gnupg = {
      agent = {
        enable = false;
        pinentryFlavor = "curses";
        enableSSHSupport = true;
      };
    };

  };
  # hardware = {
  # nvidia = {
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  #   modesetting.enable = true;
  #   powerManagement.enable = false;
  # };

  # opengl = {
  #   enable = true;
  # };
  # };

  services = {
    dbus.packages = [ pkgs.gcr ];
    xserver =
      {
        enable = lib.mkDefault false;
        layout = "us";
        xkbOptions = "eurosign:e";
        windowManager.bspwm.enable = true;

        displayManager.gdm = {
          enable = true;
          wayland = true;
        };
      };

    # xserver.videoDrivers = [ "nvidia" ];
  };

  fonts = {
    enableDefaultFonts = false;
    fontDir.enable = false;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [

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
      cascadia-code
    ]
    ++ (with (pkgs.glowsans); [ glowsansSC glowsansTC glowsansJ ])
    ++ (with nur-pkgs;[ san-francisco plangothic maoken-tangyuan hk-grotesk ]);
    #"HarmonyOS Sans SC" "HarmonyOS Sans TC"
    fontconfig = {
      subpixel.rgba = "none";
      antialias = true;
      hinting.enable = false;
      defaultFonts = lib.mkForce {
        serif = [ "Glow Sans SC" "Glow Sans TC" "Glow Sans J" "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" ];
        monospace = [ "SF Mono" "Fantasque Sans Mono" ];
        sansSerif = [ "Hanken Grotesk" "Glow Sans SC" ];
        emoji = [ "twemoji-color-font" "noto-fonts-emoji" ];
      };
    };
  };

  security = {

    pam = {
      u2f = {
        enable = true;
        authFile = config.rekey.secrets.u2f.path;
        control = "sufficient";
        cue = true;
      };

      loginLimits = [
        {
          domain = "*";
          type = "-";
          item = "memlock";
          value = "unlimited";
        }
      ];
      services.swaylock = { };
    };

    polkit.enable = true;

    # Enable sound.
    rtkit.enable = true;
  };

  # $ nix search wget
  i18n = {

    # Select internationalisation properties.
    defaultLocale = "C.UTF-8";

    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-configtool
        fcitx5-pinyin-zhwiki
      ];
    };
  };

  system.stateVersion = "22.11"; # Did you read the comment?
  documentation.nixos.enable = false;

}
