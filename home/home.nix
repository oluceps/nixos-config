{ config
, pkgs
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



  home.packages = with pkgs; [
    gnome.nautilus
    gnome.eog
    gnomecast
    sioyek
    thunderbird
    nur-pkgs.rustplayer
    nheko
    conda
    gtk4
    lapce
    vscode-with-extensions
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

    via
    discord-canary

    qemu
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

    neovim-qt
    smartmontools
    wireshark-qt
    wezterm
    android-tools
    tor-browser-bundle-bin
    cargo-cross
    # android-studio
    zellij
    netease-cloud-music-gtk
    cmatrix
    termius
    kotatogram-desktop
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
    firefox-wayland
    bluedevil
    #zathura
    jetbrains.clion
    jetbrains.goland
    jetbrains.pycharm-professional
    jetbrains.datagrip
    bspwm
    sxhkd
    tdesktop
    file
    julia-bin
    tree
    polymc
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
    git = {
      enable = true;
      userName = "oluceps";
      userEmail = "i@oluceps.uk";
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
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
