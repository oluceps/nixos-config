{ pkgs, ... }: {
  programs.starship = {
    enable = true;

    settings = {
      add_newline = false;

      format = ''$directory  $git_branch  $git_status $cmd_duration$line_break$python$character'';
      #

      directory.style = "blue";

      character = {
        success_symbol = "[>](white)";
        error_symbol = "[>](red)";
        vicmd_symbol = "[<](green)";
      };

      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
        style = "cyan";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };

      git_state = {
        format = "\([$state( $progress_current/$progress_total)]($style)\)";
        style = "bright-black";
      };

      directory = {
        truncation_length = 5;
        format = "[$path]($style)";
      };

      cmd_duration = {
        format = "[$duration]($style)";
        style = "yellow";
      };
      python = {
        format = "[$virtualenv]($style)";
        style = "bright-black";
      };

      nix_shell = {
        format = "via [$symbol$state( \($name\))]($style) ";
      };

      # package.disabled = true;
    };
  };
}
