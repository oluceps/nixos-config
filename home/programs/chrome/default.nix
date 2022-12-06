{ config, lib, pkgs, ... }:
{

  programs = {
    chromium = {
      enable = true;
      commandLineArgs = [ "--enable-features=UseOzonePlatform" "-ozone-platform=wayland" ];
    };
    google-chrome = {
      enable = true;
      commandLineArgs = [ "--enable-features=UseOzonePlatform" "-ozone-platform=wayland" ];
    };


  };

}
  
