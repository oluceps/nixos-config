{ ... }: {
  programs.fish = {
    enable = true;
    plugins = [ ];
    shellAliases = {
      nd = "cd /etc/nixos";
      swc = "doas nixos-rebuild switch --flake /etc/nixos --verbose";
      swcs = "doas nixos-rebuild switch --flake /etc/nixos --verbose --max-jobs 1";
      daso = "doas";
      daos = "doas";
      off = "poweroff";
      kls = "lsd --icon never";
      lks = "lsd --icon never";
      sl = "lsd --icon never";
      ls = "lsd --icon never";
      l = "lsd --icon never -lh";
      la = "lsd --icon never -la";
      g = "lazygit";
      "cd.." = "cd ..";
      up = "nix flake update --commit-lock-file /etc/nixos && swc";
      rekey = "nix run .#rekey";
    };

    shellInit = ''
      fish_vi_key_bindings
      set -g direnv_fish_mode eval_on_arrow
      set fish_color_normal normal
      set fish_color_command blue
      set fish_color_quote yellow
      set fish_color_redirection cyan --bold
      set fish_color_end green
      set fish_color_error brred
      set fish_color_param cyan
      set fish_color_comment red
      set fish_color_match --background=brblue
      set fish_color_selection white --bold --background=brblack
      set fish_color_search_match bryellow --background=brblack
      set fish_color_history_current --bold
      set fish_color_operator brcyan
      set fish_color_escape brcyan
      set fish_color_cwd green
      set fish_color_cwd_root red
      set fish_color_valid_path --underline
      set fish_color_autosuggestion white
      set fish_color_user brgreen
      set fish_color_host normal
      set fish_color_cancel --reverse
      set fish_pager_color_prefix normal --bold --underline
      set fish_pager_color_progress brwhite --background=cyan
      set fish_pager_color_completion normal
      set fish_pager_color_description B3A06D --italics
      set fish_pager_color_selected_background --reverse
    '';
    interactiveShellInit = ''
      # Need to declare here, since something buggy.
      # For foot `jump between prompt` function
      function mark_prompt_start --on-event fish_prompt
          echo -en "\e]133;A\e\\"
      end
    '';
    functions = {
      fish_greeting = "set_color -o EEA9A9; date +%T; set_color normal";
      # update_cwd_osc = {
      #   body = ''
      #     if status --is-command-substitution || set -q INSIDE_EMACS
      #         return
      #     end
      #     printf \e\]7\;file://%s%s\e\\ $hostname (string escape --style=url $PWD)
      #   '';
      #   onVariable = "PWD";
      #   description = "Notify terminals when $PWD changes";
      # };

      ekey = {
        body = ''
          nix run .#edit-secret $argv[1]
        '';
        description = "edit agenix-rekey secret";
      };
      dec = "rage -d -i ~/.ssh/age/priv.age $argv[1]";
      extract = ''
        set --local ext (echo $argv[1] | awk -F. '{print $NF}')
        switch $ext
          case tar  # non-compressed, just bundled
            tar -xvf $argv[1]
          case gz
            if test (echo $argv[1] | awk -F. '{print $(NF-1)}') = tar  # tar bundle compressed with gzip
              tar -zxvf $argv[1]
            else  # single gzip
              gunzip $argv[1]
            end
          case tgz  # same as tar.gz
            tar -zxvf $argv[1]
          case bz2  # tar compressed with bzip2
            tar -jxvf $argv[1]
          case rar
            unrar x $argv[1]
          case zip
            unzip $argv[1]
          case '*'
            echo "unknown extension"
        end
      '';
    };
  };
}
