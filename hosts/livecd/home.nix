{ pkgs
, config
, user
, system
, inputs
, ...
}:
let
  homeProfile = {

    imports = [
      ../../home/programs/fish
      ../../home/programs/helix
      ../../home/programs/hyprland
      ../../home/programs/waybar
      ../../home/programs/alacritty
      ../../home/programs/starship.nix
    ];
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
    };

    home.packages = with pkgs; [
      gnome.nautilus
      gnome.eog
      sioyek
      thunderbird
      nur-pkgs.rustplayer
      firefox
      nheko
      gtk4
      starship
      vlc
      firefox
      bluedevil
      #zathura
      tdesktop
      file
      julia-bin
      tree
    ];
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.nur-pkgs.Graphite-cursors;
      name = "Graphite-light-nord";
      size = 22;
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


  };
in
{
  home-manager = {
    useGlobalPkgs = true;
    # useUserPackages = true;
    users.${user} = {
      imports = [
        homeProfile
        inputs.hyprland.homeManagerModules.default
        #        
      ];
    };
    extraSpecialArgs = { inherit inputs system user; };
  };

}

