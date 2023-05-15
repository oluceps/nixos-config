{ config
, pkgs
, user
, lib
, ...
}: {

  wayland.windowManager.sway =
    let
      wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
      wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";
      genDeps = n: lib.genAttrs n (name: lib.getExe pkgs.${name});
      deps = genDeps [
        "fuzzel"
        "foot"
        "grim"
        "light"
        "playerctl"
        "pulsemixer"
        "slurp"
        "swaybg"
        "hyprpicker"
        "cliphist"
        "firefox"
        "tdesktop"
        "save-clipboard-to"
        "screen-recorder-toggle"
        "systemd-run-app"
      ];
    in
    {

      package = null;
      enable = true;
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
        modifier = if user == "riro" then "Mod4" else "Mod1";
        startup = [
          { command = "fcitx5 -d"; }
          { command = with pkgs; "${lib.getExe systemd-run-app} ${lib.getExe firefox}"; }
          { command = with pkgs; "${lib.getExe systemd-run-app} ${lib.getExe tdesktop}"; }
          { command = with deps; "${wl-paste} --type text --watch ${cliphist} store"; } #Stores only text data
          { command = with deps; "${wl-paste} --type image --watch ${cliphist} store"; } #Stores image data
        ];
        gaps = {
          inner = 2;
          outer = 1;
          smartGaps = true;
        };
        bars = [ ];

        colors = {
          focused = {
            background = "#787878";
            border = "#f0c9cf";
            childBorder = "#D7C4BB";
            indicator = "#E1A679";
            text = "#ffffff";
          };
          unfocused = {
            background = "#2b3339";
            border = "#597B84";
            childBorder = "#597B84";
            indicator = "#E1A679";
            text = "#888888";
          };
          urgent = {
            background = "#e68183";
            border = "#DB8E71";
            childBorder = "#DB8E71";
            indicator = "#a7c080";
            text = "#ffffff";
          };
          background = "a7c080";
        };

        workspaceOutputAssign = [
          {
            output = "VGA-1";
            workspace = "1";
          }
        ];

        output =
          if user == "riro" then {
            VGA-1 = {
              # bg = "/etc/nixos/.attachs/wall.jpg fill";
              mode = "1920x1080";
              scale = "1";
            };
          } else {

            eDP-1 = {
              bg = "/etc/nixos/.attachs/wall.jpg fill";
              mode = "1366x768";
              scale = "1";
            };
          };

        window.hideEdgeBorders = "smart";
        keybindings =
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
            fuzzelArgs = "-I -l 7 -x 8 -y 7 -P 9 -b ede3e7d9 -r 3 -t 8b614db3 -C ede3e7d9 -f 'Maple Mono SC NF:style=Regular:size=15' -P 10 -B 7";
          in
          with pkgs; lib.mkOptionDefault
            ({
              "${modifier}+h" = "focus left";
              "${modifier}+j" = "focus down";
              "${modifier}+k" = "focus up";
              "${modifier}+l" = "focus right";
              "${modifier}+i" = "move scratchpad";
              "${modifier}+q" = "kill";
              "${modifier}+Shift+q" = null;
              "${modifier}+Ctrl+i" = "scratchpad show";

              "${modifier}+Ctrl+h" = "move left";
              "${modifier}+Ctrl+j" = "move down";
              "${modifier}+Ctrl+k" = "move up";
              "${modifier}+Ctrl+l" = "move right";
              "${modifier}+Ctrl+s" = "exec ${deps.save-clipboard-to}";


              "XF86AudioMute" = "exec pamixer --toggle-mute";
              "XF86AudioRaiseVolume" = "exec pamixer -i 5";
              "XF86AudioLowerVolume" = "exec pamixer -d 5";
              "XF86MonBrightnessUp" = "exec brightnessctl set +3%";
              "XF86MonBrightnessdown" = "exec brightnessctl set 3%-";
              "${modifier}+Return" = "exec ${lib.getExe systemd-run-app} ${lib.getExe alacritty}";
              "${modifier}+d" = "exec ${lib.getExe fuzzel} ${fuzzelArgs}";
              "${modifier}+space" = "floating toggle";
              "${modifier}+Shift+space" = null;
              "Print" = "exec ${lib.getExe sway-contrib.grimshot} copy area";
              "Alt+Print" = "exec ${deps.grim} - | ${wl-copy} -t image/png";
              "Ctrl+Shift+l" = "exec ${lib.getExe swaylock}";
              "${modifier}+Ctrl+p" = "exec ${lib.getExe cliphist} list | ${lib.getExe fuzzel} -d ${lib.getExe fuzzelArgs} | ${lib.getExe cliphist} decode | ${wl-copy}";
              "${modifier}+shift+r" = "exec ${lib.getExe screen-recorder-toggle}";
            }
            # override default
            // (lib.listToAttrs ((map (n: { name = "${modifier}+Shift+${n}"; value = null; })) [ "h" "j" "k" "l" ]))
            // (lib.listToAttrs ((map (n: { name = "${modifier}+Shift+${toString n}"; value = null; })) (lib.range 1 9)))
            // (lib.listToAttrs ((map (n: { name = "${modifier}+Ctrl+${toString n}"; value = "move container to workspace number ${toString n}"; })) (lib.range 1 9)))
            )
        ;
      };
    };
}







