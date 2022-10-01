{ inputs
, system
, pkgs
, ...
}: {
  #  home.file.".config/helix/".source = ./config;
  xdg.configFile = {
    "helix/languages.toml".text = builtins.readFile ./config/languages.toml;
    "helix/themes/catppuccin_macchiato.toml".text = builtins.readFile ./config/themes/catppuccin_macchiato.toml;
  };

  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${system}.default;

    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        line-number = "relative";
        auto-pairs = true;
        true-color = true;
        cursorline = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "│";
        };

        file-picker.hidden = false;

        statusline = {
          left = [ "mode" "spinner" ];
          center = [ "file-name" ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
          separator = "│";


        };

      };

      keys.normal = {
        space = {
          s = ":w";
          m = ":format";
        };

        q.q = ":q!";
        C-j = [
          "move_line_down"
          "move_line_down"
          "move_line_down"
          "move_line_down"
          "move_line_down"

        ];
        C-k = [
          "move_line_up"
          "move_line_up"
          "move_line_up"
          "move_line_up"
          "move_line_up"
        ];
        C-e = "scroll_down";
        C-y = "scroll_up";

      };
      keys.select = {
        C-j = [
          "extend_line_down"
          "extend_line_down"
          "extend_line_down"
          "extend_line_down"
          "extend_line_down"
        ];
        C-k = [
          "extend_line_up"
          "extend_line_up"
          "extend_line_up"
          "extend_line_up"
          "extend_line_up"
        ];
      };


    };
  };
}
