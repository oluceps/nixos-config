{ pkgs, lib, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ ./alacritty.yml ];
      font = { size = 15; };
      shell = {
        program = lib.getExe pkgs.fish;
      };
    };
  };
}
