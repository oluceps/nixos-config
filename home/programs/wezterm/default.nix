{ pkgs, ... }: {

  home.packages = [ pkgs.wezterm-n ];
  xdg.configFile."wezterm/wezterm.lua".text = builtins.readFile ./wezterm.lua;
}
