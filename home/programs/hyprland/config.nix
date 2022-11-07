{ pkgs
, user
, #  nix-colors,
  ...
}:
let

  emoji = "${pkgs.wofi-emoji}/bin/wofi-emoji";
  launcher = "${pkgs.fuzzel}/bin/fuzzel";
  term = "${pkgs.kitty}/bin/kitty";
  grim = "${pkgs.grim}/bin/grim";
  light = "${pkgs.light}/bin/light";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pulsemixer = "${pkgs.pulsemixer}/bin/pulsemixer";
  amixer = "${pkgs.pamixer}/bin/amixer";
  slurp = "${pkgs.slurp}/bin/slurp";
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  swaybg = "${pkgs.swaybg}/bin/swaybg";



  configText = ''

            monitor=VGA-1,preferred,auto,1
    #        monitor=VGA-1,transform,1
            #workspace=VGA-1,1

            exec-once=${swaybg} -i /home/${user}/Pictures/Wallpapers/96668523_p0.png
            exec-once=fcitx5
            exec-once=mako
            exec-once=waybar

            input {
                kb_layout=ro

                follow_mouse=1
                force_no_accel=1

                touchpad {
                  natural_scroll=1
                }
            }

            general {
                sensitivity=1.5
                main_mod=SUPER
                cursor_inactive_timeout=30

                gaps_in=3
                gaps_out=3
                border_size=2
                damage_tracking=full

                col.active_border=0x4DD7C4BB
                col.inactive_border=0x4D947A6D
            }

            decoration {
                rounding=11
                blur=1
                blur_size=3 # minimum 1
                blur_passes=2 # minimum 1, more passes = more resource intensive.
                drop_shadow=0

                # Your blur "amount" is blur_size * blur_passes, but high blur_size (over around 5-ish) will produce artifacts.
                # if you want heavy blur, you need to up the blur_passes.
                # the more passes, the more you can up the blur_size without noticing artifacts.
            }

            animations {
                enabled=1
                animation=windows,1,2,default
                animation=borders,1,2,default
                animation=fadein,1,2,default
                animation=workspaces,1,2,slide
            }

            dwindle {
                pseudotile=0 # enable pseudotiling on dwindle
            }

            # example window rules
            # for windows named/classed as abc and xyz
            #windowrule=move 69 420,abc
            #windowrule=size 420 69,abc
            #windowrule=tile,xyz
            #windowrule=float,abc
            #windowrule=pseudo,abc
            #windowrule=monitor 0,xyz

            bind=SUPER,RETURN,exec,${term}
            bind=SUPER,Space,exec,${launcher} -I
            bind=SUPER,Q,killactive,
            bind=SUPERSHIFT,E,exec,pkill Hyprland
            bind=SUPER,E,exec,${emoji}
            bind=SUPER,F,fullscreen,
            bind=SUPER,T,togglefloating,
            bind=SUPER,P,pseudo,
            bind=SUPERSHIFT,L,exec,swaylock
            bindm=SUPER,mouse:272,movewindow
            bindm=SUPER,mouse:273,resizewindow
            bindm=SUPERALT,mouse:272,resizewindow

            bind=,XF86AudioPlay,exec,${playerctl} play-pause
            bind=,XF86AudioPrev,exec,${playerctl} previous
            bind=,XF86AudioNext,exec,${playerctl} next
            bind=,XF86AudioRaiseVolume,exec,${pulsemixer} --change-volume +5
            bind=,XF86AudioLowerVolume,exec,${pulsemixer} --change-volume -5
            bind=,XF86AudioMute,exec,${pulsemixer} --toggle-mute

            bind=,XF86MonBrightnessUp,exec,${light} -A 5
            bind=,XF86MonBrightnessDown,exec,${light} -U 5

            # screenshot
            # selection
            $ssselection=${grim} -g "$(${slurp})" - | ${wl-copy} -t image/png
            bind=,Print,exec,$ssselection
            bind=SUPERSHIFT,R,exec,$ssselection

            # monitor
            $ssmonitor=${grim} -o "$(${slurp} -f %o -or)" - | ${wl-copy} -t image/png
            bind=CTRL,Print,exec,$ssmonitor
            bind=SUPERSHIFTCTRL,R,exec,$ssmonitor

            # all-monitors
            $ssall=${grim} - | ${wl-copy} -t image/png
            bind=ALT,Print,exec,$ssall
            bind=SUPERSHIFTALT,R,exec,$ssall

            # move focus
            bind=SUPER,H,movefocus,l
            bind=SUPER,L,movefocus,r
            bind=SUPER,K,movefocus,u
            bind=SUPER,J,movefocus,d

            # go to workspace
            bind=SUPER,grave,togglespecialworkspace,VGA-1
            bind=SUPER,1,workspace,1
            bind=SUPER,2,workspace,2
            bind=SUPER,3,workspace,3
            bind=SUPER,4,workspace,4
            bind=SUPER,5,workspace,5
            bind=SUPER,6,workspace,6
            bind=SUPER,7,workspace,7
            bind=SUPER,8,workspace,8
            bind=SUPER,9,workspace,9
            bind=SUPER,0,workspace,10

  '';
in
configText



