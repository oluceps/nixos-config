{ pkgs
, lib
, config
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
          tray = {
            height = 22;
          };

          modules-left = [ "sway/workspaces" "sway/mode" ];
          #
          # "sway/mode"
          modules-center = [ "clock" ];
          modules-right = [ "network" "temperature" "cpu" "memory" "pulseaudio" ];
          "sway/mode" = {
            format = " {}";
          };
          "sway/workspaces" = {
            format = "{name}";
            disable-scroll = true;

            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
              "5" = "";
              urgent = "";
              active = "";
              default = "";
            };
          };
          "wlr/workspaces" = {
            format = "{icon}";
            on-click = "activate";
            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
              "5" = "";
              urgent = "";
              active = "";
              default = "";
            };
          };
          "sway/window" = {
            max-length = 80;
            tooltip = false;
          };
          clock = {
            format = "{:%H:%M}";
            format-alt = "{:%a %d %b}";
            format-alt-click = "click-right";
            tooltip = false;
          };
          battery = {
            format = "{capacity}% {icon}";
            format-alt = "{time} {icon}";
            format-icons = [ "" "" "" "" "" ];
            format-charging = "{capacity}% ";
            interval = 30;
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
          };
          network = {
            interval = 1;
            interface = "wan";
            format = "{bandwidthDownOctets}";
            max-length = 10;

            min-length = 8;
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
          };

          "custom/spotify" = {
            interval = 1;
            return-type = "json";
            exec = "~/.config/waybar/modules/spotify.sh";
            exec-if = "pgrep spotify";
            escape = true;
          };
          "custom/storage" = {
            format = "{} ";
            format-alt = "{percentage}% ";
            format-alt-click = "click-right";
            return-type = "json";
            interval = 60;
            exec = "~/.config/waybar/storage.sh";
          };
          backlight = {
            format = "{icon}";
            format-alt = "{percent}% {icon}";
            format-alt-click = "click-right";
            format-icons = [ "" "" ];
            on-scroll-down = "light -A 1";
            on-scroll-up = "light -U 1";
          };
          "custom/weather" = {
            format = "{}";
            format-alt = "{alt}: {}";
            format-alt-click = "click-right";
            interval = 1800;
            return-type = "json";
            exec = "~/.config/waybar/weather.sh";
            exec-if = "ping wttr.in -c1";
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
            tooltip = false;
          };

          tray = {
            icon-size = 18;
          };
        };
      };
    };
  };
}
