{
  config,
  lib,
  ...
}:
{

  system.stateVersion = "24.05";

  users.mutableUsers = false;
  system.etc.overlay.mutable = false;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  boot = {
    supportedFilesystems = [ "tcp_bbr" ];
    inherit ((import ../sysctl.nix { inherit lib; }).boot) kernel;
  };

  
  systemd.services.trojan-server.serviceConfig.LoadCredential = (map (lib.genCredPath config)) [
    "nyaw.cert"
    "nyaw.key"
  ];

  srv = {
    openssh.enable = true;
    fail2ban.enable = true;
    dnsproxy.enable = true;
    
    # rustypaste.enable = true;
  };
  services = {
    trojan-server.enable = true;
    hysteria.instances = [
      {
        name = "only";
        serve = {
          enable = true;
          port = 4432;
        };
        credentials = [
          "key:${config.age.secrets."nyaw.key".path}"
          "cert:${config.age.secrets."nyaw.cert".path}"
        ];
        configFile = config.age.secrets.hyst-us.path;
      }
    ];
  };
}
