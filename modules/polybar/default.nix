{pkgs, lib, ...}:
{
  services.polybar = {
    enable = false;
    extraConfig = builtins.readFile ./config.ini;
  };
}
