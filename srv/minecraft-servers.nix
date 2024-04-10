{ pkgs, ... }:
{

  enable = true;
  eula = true;
  openFirewall = true;
  dataDir = "/var/lib/minecraft";
  # environmentFile=;
  servers = {
    pure = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      package = pkgs.minecraftServers.paper-server;
    };
  };
}
