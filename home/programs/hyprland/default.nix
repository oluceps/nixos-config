{ pkgs, user, system, inputs, ... }:

{

  wayland.windowManager.hyprland = {
    enable = true;
    systemdIntegration = false;
    extraConfig = import ./config.nix { inherit pkgs user system inputs; };

  };

}

