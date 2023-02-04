{ config
, pkgs
, inputs
, system
, ...
}:
{

  imports = import ./programs;
  home.stateVersion = "22.11";
  home.sessionVariables = {
    EDITOR = "hx";
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "firefox.desktop" ];
    "tg" = [ "telegramdesktop.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "pdf" = [ "sioyek.desktop" ];
    "ppt/pptx" = [ "wps-office-wpp.desktop" ];
    "doc/docx" = [ "wps-office-wps.desktop" ];
    "xls/xlsx" = [ "wps-office-et.desktop" ];
  };




  home.packages = with pkgs;

    [
      i2p
      pkgsCross.riscv64.ubootQemuRiscv64Smode
      pkgsCross.riscv64.opensbi
      ubootTools
      codeql
      foliate
      veracrypt

      # davinci-resolve
      cava

      # wpsoffice-cn

      sbctl
      qbittorrent
      #      (callPackage ../modules/packs/TDesktop-x64 { })
      qq
      protonmail-bridge

      koreader
      realvnc-vnc-viewer
      #    mathematica
      pcsctools
      ccid

      nrfconnect
      nrfutil
      # nrf-command-line-tools
      kate
      yubico-pam
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
      cinnamon.nemo
      dolphin
      # stress
      stress
      s-tui
      mprime

      calibre
      dolphin
      discord
      # krita
      #    davinci-resolve
      brightnessctl
      alacritty
      filezilla
      steam-run
      appimage-run
      lutris
      tofi
      zoom-us
      mdbook
      obsidian
      gnome.nautilus
      gnome.eog
      gnomecast
      sioyek
      thunderbird
      nheko
      conda
      gtk4
      lapce
      element-desktop-wayland
      #fluffychat
      tetrio-desktop
      ffmpeg_5-full
      swayidle
      foot

      fuzzel
      swaybg
      wl-clipboard
      wf-recorder
      mako
      grim
      slurp

      mongodb-compass

      vial
      discord-canary

      iwd

      geda

      ncdu_2 # disk space info

      # clipboard
      xsel

      thunderbird

      spotify
      nushell

      geekbench5

      wayfire

      btop

      #neovim-qt
      smartmontools
      #wireshark-qt
      wezterm
      android-tools
      tor-browser-bundle-bin
      cargo-cross
      # android-studio
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
      starship
      #texlive.
      texlive.combined.scheme-full
      vlc
      firefox
      bluedevil
      #zathura
      jetbrains.clion
      jetbrains.goland
      jetbrains.pycharm-professional
      jetbrains.datagrip
      bspwm
      tdesktop
      file
      julia-bin
      tree
    ]
    ++
    (with inputs;[
      prismlauncher.packages.${system}.default
    ])
    ++
    (with nur.repos; [
      linyinfeng.canokey-udev-rules
      linyinfeng.wemeet
      xddxdd.wechat-uos-bin
      YisuiMilena.hmcl-bin
      #      ocfox.gtk-qq
    ]) ++
    (with nur-pkgs;[
      rustplayer
      techmino
    ]) ++
    [
      (
        writeShellScriptBin "record-status" ''
          #!/usr/bin/env bash
          pid=`pgrep wf-recorder`
          status=$?
          if [ $status != 0 ]
          then
            echo '';
          else
            echo '';
          fi;
        ''
      )
      (
        writeShellScriptBin "screen-recorder-toggle" ''
          #!/usr/bin/env bash
          pid=`${pkgs.procps}/bin/pgrep wf-recorder`
          status=$?
          if [ $status != 0 ]
          then
            ${pkgs.wf-recorder}/bin/wf-recorder -g "$(${pkgs.slurp}/bin/slurp)" -f $HOME/Videos/record/$(date +'recording_%Y-%m-%d-%H%M%S.mp4');
          else
            ${pkgs.procps}/bin/pkill --signal SIGINT wf-recorder
          fi;
        ''
      )
      (
        writeShellScriptBin "save-clipboard-to" ''
          #!/usr/bin/env bash
          wl-paste > $HOME/Pictures/screenshot/$(date +'shot_%Y-%m-%d-%H%M%S.png')
        ''
      )
    ];
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.nur-pkgs.Graphite-cursors; #callPackage ../modules/packs/Graphite-cursors { };
    name = "Graphite-light-nord";
    size = 22;
  };


  home.file = {

    # ".icons/default".source = "${pkgs.Graphite}/share/icons/Graphite";
    #".config/clash".source = ./dotfiles/clash;
    #".config/nvim".source = ../modules/nvim;
    #".config/waybar".source = ./dotfiles/waybar;

    #    ".config/ranger/rc.conf".source = ./dotfiles/ranger/rc.conf;
  };
  services.swayidle = {
    enable = false;
    timeouts = [
      # {
      #   timeout = 300;
      #   command = "${pkgs.sway}/bin/swaymsg 'output * dmps off'";
      #   resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dmps on'";
      # }
      {
        timeout = 1200;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };


  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode.fhsWithPackages (ps: with ps; [ rustup zlib ]);
    };
    git = {
      enable = true;
      package = pkgs.gitFull;
      userName = "oluceps";
      userEmail = "i@oluceps.uk";
      signing = {
        key = "ECBE55269336CCCD ";
        signByDefault = true;
      };
      extraConfig = {
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
          #img-blurred = pkgs.runCommand "img.jpg"
          #            {
          #              nativeBuildInputs = with pkgs;[ imagemagick ];
          #            } "
          # convert -blur 14x5 ${img} $out
          # ";
        in
        "${img}";
      scaling = "fill";
    };
    mako = {
      enable = true;
      backgroundColor = "#1E1D2F3b";
      borderSize = 1;
      borderColor = "#96CDFB3b";
      maxVisible = 2;
      borderRadius = 12;
      defaultTimeout = 5000;
      font = "JetBrainsMono Nerd Font 12";
    };
    zsh = {
      enable = true;
      shellAliases = {
        nd = "cd /etc/nixos";
        n = "neovide";
        off = "poweroff";
        proxy = "proxychains4 -f /home/riro/.config/proxychains/proxychains.conf";
        roll = "xrandr -o left && feh --bg-scale /home/riro/Pictures/Wallpapers/95448248_p0.png && sleep 0.5; picom --experimental-backend -b";
        rolln = "xrandr -o normal && feh --bg-scale /home/riro/Pictures/Wallpapers/秋の旅.jpg && sleep 0.5;  picom --experimental-backend -b";
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
        #        {
        #          # will source zsh-autosuggestions.plugin.zsh
        #          name = "zsh-autosuggestions";
        #          src = pkgs.fetchFromGitHub {
        #            owner = "zsh-users";
        #            repo = "zsh-autosuggestions";
        #            rev = "v0.7.0";
        #            sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        #          };
        #        }
        #        {
        #          name = "enhancd";
        #          file = "init.sh";
        #          src = pkgs.fetchFromGitHub {
        #            owner = "b4b4r07";
        #            repo = "enhancd";
        #            rev = "v2.2.4";
        #            sha256 = "sha256-9/JGJgfAjXLIioCo3gtzCXJdcmECy6s59Oj0uVOfuuo=";
        #          };
        #        }
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
      #      loginShellInit = ''
      #        if
      #          [[ $(id --user $USER) == 1000 ]] && [[ $(tty) == "/dev/tty1" ]]
      #        then
      #          exec sway
      #        fi
      #      '';
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
        "--height 40%"
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
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Light";
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

  };
  qt = {
    enable = true;
    platformTheme = "gtk";
  };


  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
