{ inputs, pkgs, config, lib, user, ... }:
{
  # server.

  system.stateVersion = "22.11";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  services = {
    inherit ((import ../../services.nix { inherit pkgs lib config inputs; }).services) openssh;
  };

  programs = {

    git.enable = true;
    fish.enable = true;

    starship = {
      enable = true;
      settings = (import ../../home/programs/starship { }).programs.starship.settings // {
        format = "$username$directory$git_branch$git_commit$git_status$nix_shell$cmd_duration$line_break$python$character";
      };
    };
  };
  zramSwap = {
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  systemd = {
    enableEmergencyMode = false;
    watchdog = {
      # systemd will send a signal to the hardware watchdog at half
      # the interval defined here, so every 10s.
      # If the hardware watchdog does not get a signal for 20s,
      # it will forcefully reboot the system.
      runtimeTime = "20s";
      # Forcefully reboot if the final stage of the reboot
      # hangs without progress for more than 30s.
      # For more info, see:
      #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
      rebootTime = "30s";
    };

  };

  systemd.tmpfiles.rules = [
  ];
  services = {
    tuic = {
      enable = true;
      serve = true;
      configFile = config.age.secrets.tuic-san.path;
    };
    juicity = {
      enable = true;
      serve = true;
      configFile = config.age.secrets.juic-san.path;
    };
  };
  services.caddy = {
    enable = true;
    # globalConfig = ''
    #   	order forward_proxy before file_server
    # '';
    virtualHosts = {
      "magicb.uk" = {
        hostName = "magicb.uk";
        extraConfig = ''
          tls mn1.674927211@gmail.com
          file_server {
              root /var/www/public
          }
        '';
      };

      "pb.nyaw.xyz" = {
        hostName = "pb.nyaw.xyz";
        extraConfig = ''
          reverse_proxy 127.0.0.1:3999
          tls ${config.age.secrets."nyaw.cert".path} ${config.age.secrets."nyaw.key".path}
        '';
      };

      "nyaw.xyz" = {
        hostName = "nyaw.xyz";
        extraConfig = ''
          reverse_proxy 10.0.1.2:3000
          tls ${config.age.secrets."nyaw.cert".path} ${config.age.secrets."nyaw.key".path}
          redir /matrix https://matrix.to/#/@sec:nyaw.xyz
      
          header /.well-known/matrix/* Content-Type application/json
          header /.well-known/matrix/* Access-Control-Allow-Origin *
          respond /.well-known/matrix/server `{"m.server": "matrix.nyaw.xyz:443"}`
          respond /.well-known/matrix/client `{"m.homeserver": {"base_url": "https://matrix.nyaw.xyz"},"org.matrix.msc3575.proxy": {"url": "https://matrix.nyaw.xyz"}}`
        '';
      };
      "matrix.nyaw.xyz" = {
        hostName = "matrix.nyaw.xyz";
        extraConfig = ''
          	reverse_proxy /_matrix/* 10.0.1.2:6167
        '';
      };
    };

  };
}
