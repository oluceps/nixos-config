{ config
, lib
, pkgs
, ...
}: {

  wayland.windowManager.sway = {

    package = null;
    enable = true;
    #    extraConfig = ''
    #      exec dbus-sway-environment
    #      exec configure-gtk
    #    '';
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # Fix for some Java AWT applications (e.g. Android Studio),
      # use this if they aren't displayed properly:
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
    wrapperFeatures.gtk = true;
    config = {
      modifier = "Mod4";
      startup = [
        { command = "fcitx5 -d"; }
        { command = "firefox"; }
      ];
      gaps = {
        inner = 2;
        outer = 1;
      };
      bars = [ ];

      colors = {
        focused = {
          background = "#787878";
          border = "#787878";
          childBorder = "#787878";
          indicator = "#a7c080";
          text = "#ffffff";
        };
        unfocused = {
          background = "#2b3339";
          border = "#2b3339";
          childBorder = "#2b3339";
          indicator = "#a7c080";
          text = "#888888";
        };
        urgent = {
          background = "#e68183";
          border = "#e68183";
          childBorder = "#e68183";
          indicator = "#a7c080";
          text = "#ffffff";
        };
      };

      workspaceOutputAssign = [
        {
          output = "VGA-1";
          workspace = "1";
        }
      ];

      output = {
        VGA-1 = {
          bg = "~/Pictures/Wallpapers/99030258_p0.jpg fill";
          mode = "1920x1080";
          scale = "1";
        };
        #        HDMI-A-1 = {
        #          bg = "~/Pictures/Wallpapers/rurudo-purple.jpg fill";
        #          mode = "1920x1080";
        #          scale = "1.5";
        #          position = "0 0";
        #          # transform = "180";
        #        };
      };

      window.hideEdgeBorders = "smart";
      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
        in
        pkgs.lib.mkOptionDefault {
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          "${modifier}+i" = "move scratchpad";
          "${modifier}+Shift+i" = "scratchpad show";
          "${modifier}+q" = "kill";
          "${modifier}+Shift+q" = null;
          "XF86AudioMute" = "exec pamixer --toggle-mute";
          "XF86AudioRaiseVolume" = "exec pamixer -i 5";
          "XF86AudioLowerVolume" = "exec pamixer -d 5";
          "XF86MonBrightnessUp" = "exec brightnessctl set +3%";
          "XF86MonBrightnessdown" = "exec brightnessctl set 3%-";
          #"${modifier}+Shift+e" = "exec power-menu";
          "${modifier}+Return" = "exec ${pkgs.wezterm}/bin/wezterm";
          "${modifier}+d" = "exec ${pkgs.fuzzel}/bin/fuzzel -I";
          "${modifier}+space" = "floating toggle";
          "${modifier}+Shift+space" = null;
          "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area";
          "Ctrl+Shift+l" = "exec ${pkgs.swaylock}/bin/swaylock";
          #"${modifier}+shift+r" = "exec screen-recorder-toggle";
        };
    };
  };
}
