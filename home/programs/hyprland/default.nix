{ pkgs, user, ... }:

{

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemdIntegration = false;
    extraConfig = import ./config.nix { inherit pkgs user; };
    nvidiaPatches = true;
    recommendedEnvironment = true;
    xwayland = {
      enable = true;
      hidpi = false;
    };
  };

  home = {
    sessionVariables = {
      EDITOR = "hx";
      TERMINAL = "foot";
      QT_SCALE_FACTOR = "1";
      MOZ_ENABLE_WAYLAND = "1";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
      WLR_NO_HARDWARE_CURSORS = "1";
      #GBM
      GBM_BACKEND = "nvidia-drm";
      CLUTTER_BACKEND = "wayland";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_CACHE_HOME = "\${HOME}/.cache";
      XDG_CONFIG_HOME = "\${HOME}/.config";
      XDG_BIN_HOME = "\${HOME}/.local/bin";
      XDG_DATA_HOME = "\${HOME}/.local/share";
    };
  };

}

