{ config
, pkgs
, inputs
, system
, ...
}:
{

  imports =
    map (d: ./programs + d)
      (map (n: "/" + n)
        (with builtins;attrNames
          (readDir ./programs)));

  home.stateVersion = "22.11";
  home.sessionVariables = {
    EDITOR = "hx";
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  home.packages = with pkgs;

    [
      hyfetch
      qq
      microsoft-edge
      dosbox-staging
      meld
      yubioath-flutter
      libsForQt5.qtbase
      libsForQt5.qtwayland
      openapi-generator-cli


      veracrypt
      openpgp-card-tools
      tutanota-desktop

      # davinci-resolve
      cava

      wpsoffice-cn

      sbctl
      qbittorrent

      protonmail-bridge

      koreader
      cliphist
      # realvnc-vnc-viewer
      #    mathematica
      pcsctools
      ccid

      nrfconnect
      nrfutil
      # nrf-command-line-tools
      yubikey-manager

      xdeltaUnstable
      xterm

      feeluown
      feeluown-bilibili
      feeluown-local
      feeluown-netease
      feeluown-qqmusic

      chntpw
      gkraken
      libnotify

      # Perf
      stress
      s-tui
      mprime

      # reader
      calibre
      dolphin
      obsidian
      mdbook
      sioyek
      foliate

      # file
      filezilla
      file
      lapce
      kate
      cinnamon.nemo
      dolphin
      gnome.nautilus
      gnome.eog
      #zathura

      # social
      discord
      tdesktop
      nheko
      element-desktop-wayland
      thunderbird
      # fluffychat
      discord-canary
      scrcpy

      alacritty
      steam-run
      appimage-run
      lutris
      tofi
      zoom-us
      gnomecast
      tetrio-desktop

      ffmpeg_5-full

      foot

      brightnessctl

      fuzzel
      swaybg
      wl-clipboard
      wf-recorder
      grim
      slurp

      mongodb-compass
      tor-browser-bundle-bin

      vial

      geda

      ncdu_2 # disk space info

      btop

      smartmontools
      android-tools
      cargo-cross
      zellij
      netease-cloud-music-gtk
      cmatrix
      termius
      # kotatogram-desktop
      autojump
      nmap
      lm_sensors
      eww-wayland
      rofi
      picom

      feh
      pamixer
      sl
      ncpamixer
      texlive.combined.scheme-full
      vlc
      bluedevil
      # jetbrains.clion
      # jetbrains.goland
      # jetbrains.pycharm-professional
      # jetbrains.datagrip
      julia-bin
    ]
    ++
    (with inputs;[
      prismlauncher.packages.${system}.default
    ])
    ++
    (with nur.repos; [
      linyinfeng.canokey-udev-rules
      YisuiMilena.hmcl-bin
    ]) ++
    (with nur-pkgs;[
      # rustplayer
      techmino
    ]);
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.Graphite-cursors;
    name = "Graphite-light-nord";
    size = 22;
  };

  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode.fhsWithPackages (ps: with ps; [ rustup zlib ]);
    };
    jq.enable = true;
    lf.enable = true;
    pandoc.enable = true;
    git = {
      enable = true;
      package = pkgs.gitFull;
      userName = "oluceps";
      userEmail = "i@oluceps.uk";
      # signing = {
      #   key = "ECBE55269336CCCD";
      #   signByDefault = true;
      # };
      extraConfig = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = "~/.ssh/id_ed25519.pub";
        merge.conflictStyle = "diff3";
        merge.tool = "vimdiff";
        mergetool = {
          keepBackup = false;
          keepTemporaries = false;
          writeToTemp = true;
        };
        pull.rebase = true;
        fetch.prune = true;

        sendemail = {
          smtpserver = "smtp.gmail.com";
          smtpencryption = "tls";
          smtpserverport = 587;
          smtpuser = "mn1.674927211@gmail.com";
          from = "mn1.674927211@gmail.com";
        };
      };
    };
    swaylock.settings = {
      show-failed-attempts = true;
      daemonize = true;
      image =
        let
          img = pkgs.fetchurl {
            url = "https://maxwell.ydns.eu/git/rnhmjoj/nix-slim/raw/branch/master/background.png";
            name = "img.jpg";
            hash = "sha256-kqvVGHOaD7shJrvYfhLDvDs62r20wi8Sajth16Spsrk=";
          };
          img-blurred = pkgs.runCommand "img.jpg"
            {
              nativeBuildInputs = with pkgs;[ imagemagick ];
            } "
           convert -blur 14x5 ${img} $out
           ";
        in
        "${img-blurred}";
      scaling = "fill";
    };
    zsh = {
      enable = true;
      shellAliases = {
        nd = "cd /etc/nixos";
        n = "neovide";
        off = "poweroff";
        # roll = "xrandr -o left && feh --bg-scale /home/riro/Pictures/Wallpapers/95448248_p0.png && sleep 0.5; picom --experimental-backend -b";
        # rolln = "xrandr -o normal && feh --bg-scale /home/riro/Pictures/Wallpapers/秋の旅.jpg && sleep 0.5;  picom --experimental-backend -b";
        cat = "bat";
        kls = "exa";
        sl = "exa";
        ls = "exa";
        l = "exa -l";
        la = "exa -la";
        g = "lazygit";
      };
      history = {
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
        share = true;
        path = "${config.xdg.dataHome}/zsh_history";
      };

      enableAutosuggestions = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      autocd = true;
      dotDir = ".config/zsh";
      defaultKeymap = "emacs";
      initExtra = ''
        eval $(starship init zsh)
      '';
      loginExtra = ''
        if
          [[ $(id --user $USER) == 1000 ]] && [[ $(tty) == "/dev/tty1" ]]
        then
          exec sway
        fi
      '';

      plugins = [
        {
          name = "zsh-history-substring-search";
          file = "zsh-history-substring-search.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-history-substring-search";
            rev = "4abed97b6e67eb5590b39bcd59080aa23192f25d";
            sha256 = "sha256-8kiPBtgsjRDqLWt0xGJ6vBBLqCWEIyFpYfd+s1prHWk=";
          };
        }
        {
          name = "sudo";
          file = "plugins/sudo/sudo.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "ohmyzsh";
            repo = "ohmyzsh";
            rev = "957dca698cd0a0cafc6d2551eeff19fe223f41bd";
            sha256 = "sha256-fafbsXO29/lqLDcffkdEiXrC9R7PJiRuyNSlTUTErdI=";
          };
        }
        {
          name = "man";
          file = "plugins/man/man.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "ohmyzsh";
            repo = "ohmyzsh";
            rev = "25d0b2dfbd4f4c915a9c04e29a97b82ebd4e612c";
            sha256 = "sha256-fafbsXO29/lqLDcffkdEiXrC9R7PJiRuyNSlTUTErdI=";
          };
        }
      ];
    };
    autojump.enable = true;

    obs-studio = {
      enable = true;
      plugins = with pkgs; [ obs-studio-plugins.wlrobs ];
    };

    home-manager.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 80%"
        "--layout=reverse"
        "--info=inline"
        "--border"
        "--exact"
      ];
    };

    #    neovim = {
    #      enable = true;
    #      vimAlias = true;
    #      vimdiffAlias = true;
    #      plugins = with pkgs.vimPlugins; [
    #        telescope-nvim
    #        nvim-lspconfig
    #        fidget-nvim
    #        nvim-cmp
    #        catppuccin-nvim
    #        cmp-nvim-lsp
    #        indent-blankline-nvim
    #        everforest
    #        luasnip
    #        vim-lastplace
    #        which-key-nvim
    #        editorconfig-nvim
    #        lualine-nvim
    #        lspsaga-nvim
    #        lualine-lsp-progress
    #        #vim-wakatime
    #        vimspector
    #        nvim-notify
    #        nvim-dap
    #        nvim-dap-ui
    #        rust-tools-nvim
    #        nerdtree
    #        surround
    #        auto-pairs
    #        nvim-ts-rainbow
    #        nvim-treesitter-context
    #        dashboard-nvim
    #        null-ls-nvim
    #        lspkind-nvim
    #        cmp-treesitter
    #        (nvim-treesitter.withPlugins (
    #          plugins: with plugins; [
    #            tree-sitter-nix
    #            tree-sitter-lua
    #            tree-sitter-rust
    #            tree-sitter-go
    #
    #          ]
    #        ))
    #      ]; #
    #      #extraConfig = ''
    #      #
    #      #        set viminfo+=n${config.xdg.stateHome}/viminfo
    #      #        lua << EOT
    #      #        ${builtins.readFile ../modules/nvim.lua}
    #      #        EOT
    #      #      '';
    #    };
    #nushell = {
    #  enable = true;
    #  settings = {
    #    edit_mode = "vi";
    #    startup = [ "alias la [] { ls -a }" "alias e [msg] { echo $msg }" "alias nd {cd /etc/nixos}"];
    #    completion_mode = "circular";
    #    no_auto_pivot = true;
    #  };
    #};
    #
  };
  #xdg.configFile."sway/config".text = import ./dotfiles/sway/config.nix {inherit config pkgs;};
  #xdg.configFile."ss/config".text = import ./programs/ss.nix {inherit config pkgs;};
  gtk = {
    enable = true;
    theme = {
      package = pkgs.materia-theme;
      name = "Materia-light";
    };

    iconTheme = {
      package = pkgs.fluent-icon-theme;
      name = "Fluent";
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

  };
  qt = {
    enable = true;
    platformTheme = "gtk";
  };


  services = {
    swayidle = {
      enable = true;
      timeouts = [
        { timeout = 900; command = "${pkgs.swaylock}/bin/swaylock"; }
      ];
      events = [
        { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
      ];
    };
    mako = {
      enable = true;
      backgroundColor = "#1E1D2F3b";
      borderSize = 0;
      borderColor = "#96CDFB3b";
      maxVisible = 2;
      borderRadius = 5;
      defaultTimeout = 5000;
      font = "JetBrainsMono Nerd Font 12";
    };
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };
}
