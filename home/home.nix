{ config
, pkgs
, lib
, inputs
, ...
}:
{

  imports =
    map (d: ./programs + d)
      (map (n: "/" + n)
        (with builtins;attrNames
          (lib.filterAttrs (n: _: !elem n [ "hyprland" ])  # one or more of them conflict with gnome  "sway" "hyprland" "waybar"
            (readDir ./programs))));

  home.stateVersion = "22.11";

  home.sessionVariables = {
    EDITOR = "hx";
  };

  android-sdk.enable = true;

  android-sdk.packages = sdk: with sdk; [
    # build-tools-31-0-0
    cmdline-tools-latest
    # emulator
    # platforms-android-31
    # sources-android-31
  ];

  systemd.user = {
    sessionVariables = {
      CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse";
      CARGO_UNSTABLE_SPARSE_REGISTRY = "true";
      NEOVIDE_MULTIGRID = "1";
      NEOVIDE_WM_CLASS = "1";
      NODE_PATH = "~/.npm-packages/lib/node_modules";
    };
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  home.packages = with pkgs;

    [
      anyrun
      # factorio
      logseq
      jetbrains.pycharm-professional
      jetbrains.idea-ultimate
      jetbrains.clion

      # bottles

      kooha # recorder

      typst
      blender-hip
      ruffle

      fractal

      yuzu-mainline
      photoprism

      virt-manager
      xdg-utils
      fluffychat
      mpv
      hyfetch

      # microsoft-edge
      dosbox-staging
      meld
      # yubioath-flutter
      libsForQt5.qtbase
      libsForQt5.qtwayland
      openapi-generator-cli

      gimp
      imv


      veracrypt
      openpgp-card-tools
      tutanota-desktop

      # davinci-resolve
      cava

      # wpsoffice-cn

      sbctl
      qbittorrent

      protonmail-bridge

      koreader
      cliphist
      # realvnc-vnc-viewer
      #    mathematica
      pcsctools
      ccid

      # nrfconnect
      nrfutil
      # nrf-command-line-tools
      yubikey-manager

      xdeltaUnstable
      xterm

      feeluown
      feeluown-bilibili
      # feeluown-local
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
      obsidian
      mdbook
      sioyek
      zathura
      foliate

      # file
      filezilla
      file
      lapce
      kate
      # cinnamon.nemo
      gnome.nautilus
      gnome.eog
      gnome.dconf-editor
      gnome.gnome-boxes
      #zathura

      # social
      # discord
      tdesktop
      nheko
      element-desktop-wayland
      thunderbird
      # fluffychat
      discord-canary
      scrcpy

      alacritty
      rio
      appimage-run
      lutris
      tofi
      zoom-us
      # gnomecast
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

      ncdu_2 # disk space info

      btop

      smartmontools
      android-tools
      zellij
      # netease-cloud-music-gtk
      cmatrix
      termius
      # kotatogram-desktop
      nmap
      lm_sensors

      feh
      pamixer
      sl
      ncpamixer
      # texlive.combined.scheme-full
      vlc
      bluedevil
      julia-bin
      prismlauncher
    ]
    ++
    (with nur.repos; [
      # linyinfeng.canokey-udev-rules
      xddxdd.dingtalk
    ]) ++
    (with nur-pkgs;[
      techmino
      rustplayer
    ]);
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.graphite-cursors;
    name = "graphite-light-nord";
    size = 22;
  };

  programs = {
    yazi.enable = true;
    zoxide.enable = true;
    # swww.enable = false;
    bash.enable = true;
    vscode = {
      enable = true;
      package = pkgs.vscode.fhsWithPackages (ps: with ps; [ rustup zlib ]);
    };
    jq.enable = true;
    pandoc.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
      package = pkgs.gitFull;
      userName = "oluceps";
      userEmail = "i@oluceps.uk";
      extraConfig = {
        # user.signingKey = "/run/agenix/id_sk";
        tag.gpgsign = true;
        safe.directory = "/etc/nixos";
        core.editor = with pkgs; (lib.getExe helix);
        commit.gpgsign = true;
        gpg = {
          format = "ssh";
          ssh.defaultKeyCommand = "ssh-add -L";
          ssh.allowedSignersFile = toString (pkgs.writeText "allowed_signers" "");
        };
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

    zsh = {
      enable = true;
      shellAliases = {
        nd = "cd /etc/nixos";
        n = "neovide";
        off = "poweroff";
        cat = "bat";
        kls = "eza";
        sl = "eza";
        ls = "eza";
        l = "eza -l";
        la = "eza -la";
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
      # syntaxHighlighting.enable = true;
      autocd = true;
      dotDir = ".config/zsh";
      defaultKeymap = "emacs";
      initExtra = ''
        eval $
        (starship init zsh)
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
      package = pkgs.callPackage
        "${inputs.nixpkgs}/pkgs/data/themes/fluent-gtk-theme"
        {
          themeVariants = [ "purple" ];
          tweaks = [ "blur" ];
        };
      name = "Fluent-purple";
    };

    iconTheme = {
      package = pkgs.fluent-icon-theme;
      name = "Fluent";
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

  };

  services = {
    swayidle = {
      enable = true;
      systemdTarget = "sway-session.target";
      timeouts = [
        { timeout = 900; command = "${pkgs.swaylock}/bin/swaylock"; }
        {
          timeout = 905;
          command = ''${pkgs.sway}/bin/swaymsg "output * dpms off"'';
          resumeCommand = ''${pkgs.sway}/bin/swaymsg "output * dpms on"'';
        }
      ];
      events = [
        { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
      ];
    };
    mako = {
      enable = true;
      backgroundColor = "#1E1D2Fa6";
      borderSize = 0;
      borderColor = "#96CDFB3b";
      maxVisible = 2;
      borderRadius = 5;
      defaultTimeout = 5000;
      font = "JetBrainsMono Nerd Font 12";
    };
    gpg-agent = {
      enable = false;
      defaultCacheTtl = 1800;
      enableSshSupport = false;
    };
  };
}
