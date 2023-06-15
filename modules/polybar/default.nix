{ pkgs, lib, ... }:
{
  services.polybar = {
    enable = lib.mkDefault false;
    extraConfig = builtins.readFile ./config.ini;
  };
}
