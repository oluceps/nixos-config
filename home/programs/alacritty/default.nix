{ pkgs, lib, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ ./alacritty.yml ];
      font = { size = 13.5; };
      shell = {
        program = lib.getExe pkgs.fish;
      };
    };
  };
}
