{ pkgs
, lib
, ...
}:
{
  xdg.configFile =
    let
      settingsFormat = pkgs.formats.toml { };
    in
    {
      "helix/languages.toml".text =
        builtins.readFile (settingsFormat.generate "config.toml" (import ./languages.nix { inherit pkgs lib; }));
      "helix/themes/catppuccin_macchiato.toml".text =
        builtins.readFile (settingsFormat.generate "catppuccin_macchiato.toml" (import ./catppuccin_macchiato.nix));
    };

  programs.helix = {
    enable = true;
    package = pkgs.helix;

    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        line-number = "relative";
        auto-pairs = true;
        true-color = true;
        cursorline = true;
        color-modes = true;
        soft-wrap = { enable = false; };

        lsp = {
          enable = true;
          display-messages = true;
          display-inlay-hints = true;
          snippets = true;
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "┊";
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
          q = ":q!";
        };

        C-j = map (_: "move_line_down") (lib.range 0 4);
        C-k = map (_: "move_line_up") (lib.range 0 4);
        C-e = "scroll_down";
        C-y = "scroll_up";

      };
      keys.select = {
        C-j = map (_: "extend_line_down") (lib.range 0 4);
        C-k = map (_: "extend_line_up") (lib.range 0 4);
      };
    };
  };
}
