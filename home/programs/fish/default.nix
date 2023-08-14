{ ... }: {
  programs.fish = {
    enable = true;
    plugins = [ ];
    shellAliases = {
      nd = "cd /etc/nixos";
      swc = "sudo nixos-rebuild switch --flake /etc/nixos";
      #--log-format internal-json -v 2>&1 | nom --json";
      daso = "sudo";
      daos = "sudo";
      off = "poweroff";
      mg = "kitty +kitten hyperlinked_grep --smart-case $argv .";
      kls = "lsd --icon never --hyperlink auto";
      lks = "lsd --icon never --hyperlink auto";
      sl = "lsd --icon never --hyperlink auto";
      ls = "lsd --icon never --hyperlink auto";
      l = "lsd --icon never --hyperlink auto -lh";
      la = "lsd --icon never --hyperlink auto -la";
      g = "lazygit";
      "cd.." = "cd ..";
      up = "nix flake update --commit-lock-file /etc/nixos && swc";
      rekey = "pushd /etc/nixos;nix run .#rekey;popd";
      fp = "fish --private";
      e = "exit";
      rp = "rustplayer";
      y = "yazi";
      i = "kitty +kitten icat $argv";
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
      set fish_cursor_default block blink
      set fish_cursor_insert line blink
      set fish_cursor_replace_one underscore blink
    '';
    interactiveShellInit = ''
      # Need to declare here, since something buggy.
      # For foot `jump between prompt` function
      function mark_prompt_start --on-event fish_prompt
          echo -en "\e]133;A\e\\"
      end

      function fish_user_key_bindings
          for mode in insert default visual
            bind -M $mode \cf forward-char
          end
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

      swcs = {
        body = "doas nixos-rebuild switch --flake /etc/nixos --verbose --max-jobs $argv[1]";
        description = "specific job max for rebuild";
      };
      ekey = {
        body = ''
          pushd /etc/nixos
          nix run .#edit-secret $argv[1]
          popd
        '';
        description = "edit agenix-rekey secret";
      };
      dec = "rage -d -i /run/agenix/age $argv[1]";
      enc = ''
        rage -i /etc/nixos/sec/age-yubikey-identity-7d5d5540.txt.pub -R /run/agenix/pub -e $argv[1] -o $argv[1].age
        srm $argv[1]
      '';
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
