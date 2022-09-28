{
    xdg.configFile."wezterm/wezterm.lua".text = builtins.readFile ./wezterm.lua;

    xdg.configFile."wezterm/catppuccin.lua".text = builtins.readFile ./catppuccin.lua;
}
