{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ ./alacritty.yml ];
      font = { size = 12.0; };
      shell = {
        program = "${pkgs.fish}/bin/fish";
      };
    };
  };
}
