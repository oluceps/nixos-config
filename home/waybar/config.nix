{ pkgs, lib, ... }:
builtins.toJSON [
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
      interval = 1;
      tooltip = false;
    };
    "clock#2" = {
      format = "{:%M}";
      interval = 1;
      tooltip = false;
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
      "group/time"
      "temperature"
      "cpu"
      "memory"
      "battery"
      "custom/pipewire"
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
