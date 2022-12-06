{ config
, lib
, pkgs
, user
, ...
}: {
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "babelfish";
        src = pkgs.fetchFromGitHub {
          owner = "bouk";
          repo = "babelfish";
          rev = "348cc55ff299bcdce307c4edc4a17e5747c07ff4";
          sha256 = "4cbR7pqbLc8RRwlP+bUDt53C6J7KtMEJtfxzSpO0Myw=";
        };
      }


      #        {
      #          name = "grc";
      #          src = pkgs.fishPlugins.grc.src;
      #        }
      #        {
      #          name = "done";
      #          src = pkgs.fishPlugins.done.src;
      #        }
    ];
#    loginShellInit =
#      ''
#        if test (id --user $USER) -ge 1000 && test (tty) = "/dev/tty1"
#          exec Hyprland
#        end
#
#      '';

    shellAliases = {
      nd = "cd /etc/nixos";
      swc = "sudo nixos-rebuild switch";
      swcv = "sudo nixos-rebuild switch --verbose";
      sduo = "sudo";
      n = "neovide";
      off = "poweroff";
      proxy = "proxychains4 -f /home/riro/.config/proxychains/proxychains.conf";
      roll = "xrandr -o left && feh --bg-scale /home/riro/Pictures/Wallpapers/95448248_p0.png && sleep 0.5; picom --experimental-backend -b";
      rolln = "xrandr -o normal && feh --bg-scale /home/riro/Pictures/Wallpapers/秋の旅.jpg && sleep 0.5;  picom --experimental-backend -b";
      kls = "exa";
      lks = "exa";
      sl = "exa";
      ls = "exa";
      l = "exa -l";
      la = "exa -la";
      g = "lazygit";
    };
    shellInit = ''
      ${pkgs.starship}/bin/starship init fish | source
    '';
    functions = {
      fish_greeting = "";
      fish_prompt = ''
         set -l nix_shell_info (
          if test -n "$IN_NIX_SHELL"
            echo -n "<nix-shell> "
         end
        )
      '';
    };
  };
}
