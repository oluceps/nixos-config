{ pkgs }: {
  home.packages = [ pkgs.wezterm-n ];
  programs.lf = {
    enable = true;
    extraConfig = ''
      set cleaner ~/.config/lf/lf_kitty_clean
      set previewer ~/.config/lf/lf_kitty_preview
    '';
  };

  xdg.configFile."lf/lf_kitty_clean".text = builtins.readFile ./lf_kitty_clean;
  xdg.configFile."lf/lf_kitty_preview".text = builtins.readFile ./lf_kitty_preview;
}

