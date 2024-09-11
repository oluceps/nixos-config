{ pkgs, lib, ... }:
builtins.toJSON (
  let
    niri = lib.getExe pkgs.niri;
  in
  [
    {
      battery = {
        format = "{capacity}";
        interval = 10;
        states = {
          critical = 10;
          warning = 25;
        };
        tooltip = false;
      };
      clock = {
        format = "{:%H:%M}";
        format-alt = "{:%a %d %b}";
        format-alt-click = "click-right";
        timezone = "Asia/Shanghai";
        tooltip = false;
      };
      "clock#1" = {
        format = "{:%H}";
        on-click = "${niri} msg action focus-workspace-up";
        on-click-right = "${niri} msg action focus-workspace-down";
        on-scroll-up = "${niri} msg action focus-column-left";
        on-scroll-down = "${niri} msg action focus-column-right";
        interval = 1;
        tooltip = false;
      };
      "clock#2" = {
        format = "{:%M}";
        on-click = "${niri} msg action focus-workspace-up";
        on-click-right = "${niri} msg action focus-workspace-down";
        on-scroll-up = "${niri} msg action focus-column-left";
        on-scroll-down = "${niri} msg action focus-column-right";
        interval = 1;
        tooltip = false;
      };
      pulseaudio = {
        tooltip = false;
        scroll-step = 1;
        format = "{volume}";
        format-muted = "=";
        on-click = lib.getExe (
          pkgs.nuenv.writeScriptBin {
            name = "switch-mute";
            script =
              let
                pamixer = pkgs.lib.getExe pkgs.pamixer;
              in
              ''
                ${pamixer} --get-mute | str trim | if $in == "false" { ${pamixer} -m } else { ${pamixer} -u }
              '';
          }
        );

      };
      cpu = {
        format = "{usage}";
        min-length = 3;
        interval = 1;
      };
      "custom/pipewire" = {
        exec = "${lib.getExe pkgs.pw-volume} status";
        format = "{percentage}";
        interval = "once";
        return-type = "json";
        signal = 8;
      };
      "custom/nirictl" = {
        on-click = "${niri} msg action focus-workspace-up";
        on-click-right = "${niri} msg action focus-workspace-down";
        on-scroll-up = "${niri} msg action focus-column-left";
        on-scroll-down = "${niri} msg action focus-column-right";
        format = "";
        tooltip = false;
      };
      "group/time" = {
        modules = [
          "clock#1"
          "clock#2"
        ];
        orientation = "vertical";
      };
      height = 35;
      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "|";
          deactivated = "-";
        };
      };
      layer = "top";
      margin-top = 5;
      memory = {
        format = "{}";
        interval = 1;
        tooltip = false;
      };
      modules-center = [
        "custom/nirictl"
        "group/time"
        "temperature"
        "cpu"
        "memory"
        "battery"
        "pulseaudio"
      ];
      modules-left = [ ];
      modules-right = [ ];
      network = {
        format = "{bandwidthDownOctets}";
        interface = "wlan0";
        interval = 1;
        tooltip = false;
      };
      position = "right";
      reload_style_on_change = true;
      spacing = 8;
      "sway/mode" = {
        format = " {}";
      };
      "sway/window" = {
        tooltip = false;
      };
      "sway/workspaces" = {
        all-outputs = true;
        disable-scroll = false;
        format = "{name}";
      };
      temperature = {
        format = "{temperatureC}";
        hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
        interval = 2;
        tooltip = false;
      };
      tray = {
        icon-size = 15;
        spacing = 5;
      };
    }
  ]
)
