# original configuration.nix w
{ inputs
, config
, pkgs
, lib
, user
, data
, ...
}: {
  disabledModules = [ "services/networking/dae.nix" ];
  age = {

    rekey = {
      extraEncryptionPubkeys = [ data.keys.ageKey ];
      masterIdentities = [ ./sec/age-yubikey-identity-7d5d5540.txt.pub ];
    };

    secrets =
      let
        genSec = ns: owner: group: mode: lib.genAttrs ns (n: { rekeyFile = ./sec/${n}.age;  inherit owner group mode; });
        genProxys = i: genSec i "proxy" "users" "740";
        genMaterial = i: genSec i user "nogroup" "400";
        genBootSec = i: genSec i "root" "root" "400";
        genWgSec = i: genSec i "systemd-network" "root" "600";
      in
      (genProxys [ "rat" "ss" "sing" "hyst-az" "hyst-am" "hyst-do" "tuic" "naive" "dae.sub" "by.sub" ]) //
      (genMaterial [ "ssh-cfg" "gh-eu" "riro.u2f" "elen.u2f" "gh-token" "age" "pub" "id" "id_sk" "minio" "prism" ]) //
      (genBootSec [ "db.key" "db.pem" ]) //
      (genWgSec [ "wg" "wgk" ]) //
      {
        dae = { rekeyFile = ./sec/dae.age; mode = "640"; owner = "proxy"; group = "users"; name = "d.dae"; };
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
        (_: "firefox.desktop")
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
    docker.enable = false;
    podman.enable = true;
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

  # systemd.services.nix-daemon.serviceConfig.Slice = "user.slice";
  nix =
    {
      package = pkgs.nixVersions.stable;
      registry = {
        nixpkgs.flake = inputs.nixpkgs;
        self.flake = inputs.self;
      };
      settings = {

        keep-outputs = true;
        keep-derivations = true;
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
          "nur-pkgs.cachix.org-1:PAvPHVwmEBklQPwyNZfy4VQqQjzVIaFOkYYnmnKco78="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        ];
        substituters = (map (n: "https://${n}.cachix.org")
          [ "nix-community" "nur-pkgs" "hyprland" "helix" "nixpkgs-wayland" ])
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
        !include ${config.age.secrets.gh-token.path}
      '';
    };

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
    sway = { enable = true; };
    kdeconnect.enable = true;
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

  services = {
    xserver =
      {
        enable = lib.mkDefault false;
        layout = "us";
        xkbOptions = "eurosign:e";
        windowManager.bspwm.enable = true;

        # displayManager.gdm = {
        # enable = false;
        # wayland = true;
        # };
      };

    # xserver.videoDrivers = [ "amdgpu" ];
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
    ]
    ++ (with (pkgs.glowsans); [ glowsansSC glowsansTC glowsansJ ])
    ++ (with nur-pkgs;[ san-francisco plangothic maoken-tangyuan hk-grotesk lxgw-neo-xihei ]);
    #"HarmonyOS Sans SC" "HarmonyOS Sans TC"
    fontconfig = {
      subpixel.rgba = "none";
      antialias = true;
      hinting.enable = false;
      defaultFonts = lib.mkForce {
        serif = [ "Glow Sans SC" "Glow Sans TC" "Glow Sans J" "Noto Serif" "Noto Serif CJK SC" "Noto Serif CJK TC" "Noto Serif CJK JP" ];
        monospace = [ "Maple Mono" "SF Mono" "Fantasque Sans Mono" ];
        sansSerif = [ "Hanken Grotesk" "Glow Sans SC" ];
        emoji = [ "twemoji-color-font" "noto-fonts-emoji" ];
      };
    };
  };

  security = {

    pam = {

      u2f = {
        enable = true;
        authFile = config.age.secrets."${user}.u2f".path;
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
      services = {
        swaylock = { };
        sudo.u2fAuth = true;
      };
    };

    polkit.enable = true;

    # Enable sound.
    rtkit.enable = true;
  };

  # $ nix search wget
  i18n = {

    # Select internationalisation properties.
    defaultLocale = "en_GB.UTF-8";

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

  documentation = {
    enable = true;
    nixos.enable = false;
    man.enable = false;
  };

  systemd.tmpfiles.rules = [
    "C /var/cache/tuigreet/lastuser - - - - ${pkgs.writeText "lastuser" "${user}"}"

    "L+ /run/gdm/.config/monitors.xml - - - - ${pkgs.writeText "gdm-monitors.xml" ''
    <monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>2</scale>
      <primary>yes</primary>
      <monitor>
        <monitorspec>
          <connector>eDP-1</connector>
          <vendor>BOE</vendor>
          <product>0x0893</product>
          <serial>0x00000000</serial>
        </monitorspec>
        <mode>
          <width>2160</width>
          <height>1440</height>
          <rate>60.001</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
    ''}"
  ];
}
