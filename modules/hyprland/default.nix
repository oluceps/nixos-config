{ pkgs, ...}:

{

  wayland.windowManager.hyprland = {
    enable = true;
    systemdIntegration = false;
    extraConfig = import ./config.nix { inherit  pkgs; };

  };

}

