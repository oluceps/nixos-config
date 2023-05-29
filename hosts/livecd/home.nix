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
      ../../home/programs/starship
    ];
    home.stateVersion = "22.11";
    home.sessionVariables = {
      EDITOR = "hx";
    };

    manual = {
      html.enable = false;
      json.enable = false;
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
      firefox
      nheko
      gtk4
      starship
      vlc
      firefox
      bluedevil
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
      ];
    };
    extraSpecialArgs = { inherit inputs system user; };
  };

}

