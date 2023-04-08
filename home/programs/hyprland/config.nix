{ pkgs
, user
,lib
, ...
}:
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
    # wl-copy
    "swaybg"
    "hyprpicker"
    "cliphist"
    "firefox"
    "tdesktop"
    # wl-paste
  ];


in
builtins.readFile ./mocha + (with deps; ''
    
    exec-once=${swaybg} -i /etc/nixos/.attachs/wall.jpg
    bind=SUPER,RETURN,exec,systemd-run-app ${foot}
    bind=SUPER,D,exec,${fuzzel} -I -l 7 -x 8 -y 7 -P 9 -b ede3e7d9 -r 3 -t 8b614db3 -C ede3e7d9 -f 'Maple Mono SC NF:style=Regular:size=15' -P 10 -B 7
    bind=SUPERSHIFT, P, exec, ${hyprpicker} -a

    bind=,XF86AudioPlay,exec,${playerctl} play-pause
    bind=,XF86AudioPrev,exec,${playerctl} previous
    bind=,XF86AudioNext,exec,${playerctl} next
    bind=,XF86AudioRaiseVolume,exec,${pulsemixer} --change-volume +5
    bind=,XF86AudioLowerVolume,exec,${pulsemixer} --change-volume -5
    bind=,XF86AudioMute,exec,${pulsemixer} --toggle-mute

    bind=,XF86MonBrightnessUp,exec,${light} -A 5
    bind=,XF86MonBrightnessDown,exec,${light} -U 5
    bind=SUPER CTRL, P, exec,  ${cliphist} list | ${fuzzel} -d -I -l 7 -x 8 -y 7 -P 9 -w 50 -b ede3e7d9 -r 3 -t 8b614db3 -C ede3e7d9 -f 'Maple Mono SC NF:style=Regular:size=15' -P 10 -B 7 | ${cliphist} decode | ${wl-copy}

    # selection
    $ssselection=${lib.getExe pkgs.sway-contrib.grimshot} copy area

    # all-monitors
    $ssall=${grim} - | ${wl-copy} -t image/png
    
    # Clipboard manager
    exec-once = ${wl-paste} --type text --watch ${cliphist} store #Stores only text data
    exec-once = ${wl-paste} --type image --watch ${cliphist} store #Stores only image data

    exec-once=systemd-run-app ${tdesktop}
    exec-once=systemd-run-app ${firefox}
  '') + builtins.readFile ./general

