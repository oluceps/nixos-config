{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ ./alacritty.yml ];
      font = { size = 12.0; };
    };
  };
}
