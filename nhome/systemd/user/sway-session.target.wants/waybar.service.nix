{ pkgs, ... }:
''
  [Install]
  WantedBy=sway-session.target

  [Service]
  ExecReload=${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID
  ExecStart=${pkgs.waybar}
  KillMode=mixed
  Restart=on-failure

  [Unit]
  After=graphical-session-pre.target
  Description=Highly customizable Wayland bar for Sway and Wlroots based compositors.
  Documentation=https://github.com/Alexays/Waybar/wiki
  PartOf=graphical-session.target
''
