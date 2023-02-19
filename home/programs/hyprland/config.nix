{ pkgs
, user
, ...
}:
let

  emoji = "${pkgs.wofi-emoji}/bin/wofi-emoji";
  launcher = "${pkgs.fuzzel}/bin/fuzzel";
  term = "${pkgs.foot}/bin/foot";
  grim = "${pkgs.grim}/bin/grim";
  light = "${pkgs.light}/bin/light";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  pulsemixer = "${pkgs.pulsemixer}/bin/pulsemixer";
  amixer = "${pkgs.pamixer}/bin/amixer";
  slurp = "${pkgs.slurp}/bin/slurp";
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  swaybg = "${pkgs.swaybg}/bin/swaybg";
  hyprpicker = "${pkgs.hyprpicker}/bin//hyprpicker";



  configText = ''

            monitor=VGA-1,1920x1080@75,auto,1
    #        monitor=VGA-1,transform,1
            #workspace=VGA-1,1

            exec-once=${swaybg} -i /home/${user}/Pictures/Wallpapers/ramiro-martinez--9z8zN8RT20-unsplash.jpg
            exec-once=fcitx5
            exec-once=mako
            exec-once=waybar
            exec-once=systemd-run-app telegram-desktop
            exec-once=systemd-run-app firefox

            input {
                kb_layout=us

                follow_mouse=1
                force_no_accel=1

                touchpad {
                  natural_scroll=1
                }
                
                sensitivity = 0
            }

            general {
                cursor_inactive_timeout=30

                gaps_in=3
                gaps_out=3
                border_size=2

                col.active_border=rgba(f0c9cfbf)
                col.inactive_border=rgba(59595940)
                layout = dwindle
            }
           dwindle {
             no_gaps_when_only = false
             force_split = 2 
             special_scale_factor = 0.8
             split_width_multiplier = 1.0 
             use_active_for_splits = true
             pseudotile = yes 
             preserve_split = yes 
           }
          
            master {
              new_is_master = true
              special_scale_factor = 0.8
              new_is_master = true
              no_gaps_when_only = false
            }
           decoration {
             multisample_edges = true
             fullscreen_opacity = 1.0
             rounding = 8
             blur = 1
             blur_size = 3
             blur_passes = 2
             blur_new_optimizations = true
             drop_shadow = false
             shadow_range = 4
             shadow_render_power = 3
             shadow_ignore_window = true
           # col.shadow = 
           # col.shadow_inactive
           # shadow_offset
             dim_inactive = false
           # dim_strength = #0.0 ~ 1.0
             blur_ignore_opacity = false
             col.shadow = rgba(1a1a1aee)
           }
           # animations {
           #   enabled = yes
           #
           #   bezier = easeOutElastic, 0.05, 0.9, 0.1, 1.05
           #   # bezier=overshot,0.05,0.9,0.1,1.1
           #
           #   animation = windows, 1, 5, easeOutElastic
           #   animation = windowsOut, 1, 5, default, popin 80%
           #   animation = border, 1, 8, default
           #   animation = fade, 1, 5, default
           #   animation = workspaces, 1, 6, default
           # }
           animations {
             enabled=1
             bezier = overshot, 0.13, 0.7, 0.29, 1.1
             animation = windows, 1, 3, overshot, slide
             animation = windowsOut, 1, 3, default, popin 80%
             animation = border, 1, 3, default
             animation = fade, 1, 2, default
             animation = workspaces, 1, 2, default
           }
            bind=SUPER,RETURN,exec,systemd-run-app ${term}
            bind=SUPER,D,exec,${launcher} -I -l 7 -x 8 -y 7 -P 9 -b ede3e7d9 -r 3 -t 8b614db3 -C ede3e7d9 -f 'Maple Mono NF:style=Regular:size=15' -P 10 -B 7
            bind=SUPERSHIFT, P, exec, ${hyprpicker} -a
            bind=SUPER,Q,killactive,
            bind=SUPERSHIFT,E,exec,pkill Hyprland
            bind=SUPER,F,fullscreen,
            bind=SUPER,Space,togglefloating,
            bind=SUPER,P,pseudo,
            bind=SUPERCTRL,L,exec,swaylock
            bindm=SUPER,mouse:272,movewindow
            bindm=SUPER,mouse:273,resizewindow

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

            # screen recorder
            bind=SUPERCTRL,R,exec,screen-recorder-toggle
            bind=SUPERCTRL,S,exec,save-clipboard-to

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
            
      bind = SUPER SHIFT,left ,movewindow, l
      bind = SUPER SHIFT,right ,movewindow, r
      bind = SUPER SHIFT,up ,movewindow, u
      bind = SUPER SHIFT,down ,movewindow, d

      bind = SUPER SHIFT,H ,movewindow, l
      bind = SUPER SHIFT,L ,movewindow, r
      bind = SUPER SHIFT,K ,movewindow, u
      bind = SUPER SHIFT,J ,movewindow, d
      bind = SUPER CTRL, 1, movetoworkspace, 1
      bind = SUPER CTRL, 2, movetoworkspace, 2
      bind = SUPER CTRL, 3, movetoworkspace, 3
      bind = SUPER CTRL, 4, movetoworkspace, 4
      bind = SUPER CTRL, 5, movetoworkspace, 5
      bind = SUPER CTRL, 6, movetoworkspace, 6
      bind = SUPER CTRL, 7, movetoworkspace, 7
      bind = SUPER CTRL, 8, movetoworkspace, 8
      bind = SUPER CTRL, 9, movetoworkspace, 9
      bind = SUPER CTRL, 0, movetoworkspace, 10
      bind = SUPER CTRL, bracketleft, movetoworkspace, -1
      bind = SUPER CTRL, bracketright, movetoworkspace, +1
      # same as above, but doesnt switch to the workspace
      bind = SUPER SHIFT, 1, movetoworkspacesilent, 1
      bind = SUPER SHIFT, 2, movetoworkspacesilent, 2
      bind = SUPER SHIFT, 3, movetoworkspacesilent, 3
      bind = SUPER SHIFT, 4, movetoworkspacesilent, 4
      bind = SUPER SHIFT, 5, movetoworkspacesilent, 5
      bind = SUPER SHIFT, 6, movetoworkspacesilent, 6
      bind = SUPER SHIFT, 7, movetoworkspacesilent, 7
      bind = SUPER SHIFT, 8, movetoworkspacesilent, 8
      bind = SUPER SHIFT, 9, movetoworkspacesilent, 9
      bind = SUPER SHIFT, 0, movetoworkspacesilent, 10
      # Scroll through existing workspaces with mainMod + scroll
      bind = SUPER, mouse_down, workspace, e-1
      bind = SUPER, mouse_up, workspace, e+1

      bind = ,mouse_down mouse:275,workspace,e-1
      bind = ,mouse_up mouse:275,workspace,e+1
      
      bind=SUPER,R,submap,resize
      submap=resize
      binde=,right,resizeactive,15 0
      binde=,left,resizeactive,-15 0
      binde=,up,resizeactive,0 -15
      binde=,down,resizeactive,0 15
      binde=,l,resizeactive,15 0
      binde=,h,resizeactive,-15 0
      binde=,k,resizeactive,0 -15
      binde=,j,resizeactive,0 15
      bind=,escape,submap,reset 
      submap=reset
      bind=CTRL SHIFT, left, resizeactive,-15 0
      bind=CTRL SHIFT, right, resizeactive,15 0
      bind=CTRL SHIFT, up, resizeactive,0 -15
      bind=CTRL SHIFT, down, resizeactive,0 15
      bind=CTRL SHIFT, l, resizeactive, 15 0
      bind=CTRL SHIFT, h, resizeactive,-15 0
      bind=CTRL SHIFT, k, resizeactive, 0 -15
      bind=CTRL SHIFT, j, resizeactive, 0 15
      
      windowrule=float,title:^(Picture-in-Picture)$
      windowrule=size 960 540,title:^(Picture-in-Picture)$
      windowrule=move 25%-,title:^(Picture-in-Picture)$
      windowrule=float,imv
      windowrule=move 25%-,imv
      windowrule=size 960 540,imv
      windowrule=float,mpv
      windowrule=move 25%-,mpv
      windowrule=size 960 540,mpv
      windowrule=float,danmufloat
      windowrule=move 25%-,danmufloat
      windowrule=pin,danmufloat
      windowrule=rounding 5,danmufloat
      windowrule=size 960 540,danmufloat
      windowrule=float,termfloat
      windowrule=move 25%-,termfloat
      windowrule=size 960 540,termfloat
      windowrule=rounding 5,termfloat
      windowrule=float,pcmanfm
      windowrule=move 25%-,pcmanfm
      windowrule=size 960 540,pcmanfm
      windowrule=animation slide right,kitty
      windowrule=animation slide right,alacritty
      windowrule=animation slide right,telegramdesktop
      windowrule=float,ncmpcpp
      windowrule=move 25%-,ncmpcpp
      windowrule=size 960 540,ncmpcpp
      windowrule=rounding 0,MATLAB R2022b - academic use
      windowrule=noborder, ^(grim)$
      windowrule=noborder, ^(slurp)$
#      windowrulev2=noanim,class:telegramdesktop,title:Telegram
      windowrulev2=animation fade,class:org.telegram.desktop,title:Media viewer
      windowrulev2=float,class:org.telegram.desktop,title:Media viewer
      
      

  '';
in
configText



