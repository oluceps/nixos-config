{ pkgs
, lib
, config
, user
, ...
}: {
  programs = {
    waybar = {
      enable = true;
      style = builtins.readFile ./waybar.css;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 22;
          modules-left = [ "wlr/workspaces" ];
          #
          # "sway/mode"
          modules-center = [ "clock" ];
          modules-right = let base = [ "network" "temperature" "cpu" "memory" "pulseaudio" ]; in
            if user == "riro" then
            # [ "tray" ] ++
              base
            else if user == "elena"
            then [ "network" "temperature" "cpu" "memory" "battery" "pulseaudio" ]
            else base;
          "sway/mode" = {
            format = " {}";
          };
          "sway/workspaces" = {
            format = "{name}";
            disable-scroll = true;
          };
          "wlr/workspaces" = {
            format = "{icon}";
            on-click = "activate";
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          "sway/window" = {
            max-length = 80;
            tooltip = false;
          };
          "tray" = {
            "icon-size" = 15;
            "spacing" = 5;
          };
          disk = {
            interval = 30;
            format = "{percentage_free}% free on {path}";
          };
          clock = {
            format = "{:%H:%M}";
            timezone = "Asia/Shanghai";
            format-alt = "{:%a %d %b}";
            format-alt-click = "click-right";
            tooltip = false;
          };
          battery = {
            format = "{capacity}% {icon}";
            format-alt = "{time} {icon}";
            format-icons = [ "" "" "" "" "" ];
            format-charging = "{capacity}% ";
            interval = 10;
            states = {
              warning = 25;
              critical = 10;
            };
            tooltip = false;
          };
          cpu = {
            interval = 1;
            format = "{usage}% ";
            max-length = 10;
            min-length = 5;
          };
          memory = {
            interval = 1;
            format = "{}% ";
            max-length = 10;
            min-length = 5;
            tooltip = false;
          };
          network = {
            interval = 1;
            interface = if user == "riro" then "wan" else "wlan";
            format = "{bandwidthDownOctets}";
            max-length = 10;
            min-length = 8;
            tooltip = false;
          };
          pulseaudio = {
            min-length = 5;
            format = "{volume}% {icon}";
            format-alt = "{volume} {icon}";
            format-alt-click = "click-right";
            format-muted = "x";
            format-icons = {
              phone = [ " " " " " 墳" " " ];
              default = [ "" "墳" "" ];
            };
            scroll-step = 1;
            tooltip = false;
          };
          temperature = {
            interval = 2;
            hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
            format = "{temperatureC}°C ";
            max-length = 10;
            min-length = 5;
            tooltip = false;
          };

          backlight = {
            format = "{icon}";
            format-alt = "{percent}% {icon}";
            format-alt-click = "click-right";
            format-icons = [ "" "" ];
            on-scroll-down = "light -A 1";
            on-scroll-up = "light -U 1";
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = false;
          };

        };
      };
    };
  };
}
