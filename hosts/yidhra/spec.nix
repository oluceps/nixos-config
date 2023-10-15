{ pkgs, config, user, ... }: {
  # Mobile device.

  system.stateVersion = "23.05"; # Did you read the comment?


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
  services.caddy = {
    enable = true;
    # globalConfig = ''
    #   	order forward_proxy before file_server
    # '';
    virtualHosts = {
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
