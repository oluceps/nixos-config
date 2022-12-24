{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      set -g status-position top
      set -g set-clipboard on
      set -g mouse on
      set -g status-right ""
      set -g renumber-windows on
      set -ga terminal-overrides ",alacritty:Tc"
      new-session -s main
    '';
  };
}
