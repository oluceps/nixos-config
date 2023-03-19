{ ... }:
{

  programs =
    let commandLineArgs = [ "--enable-wayland-ime" "--ozone-platform=wayland" ];
    in {
      chromium = {
        enable = true;
        inherit commandLineArgs;
      };
      google-chrome = {
        enable = true;
        inherit commandLineArgs;
      };
    };
}
  
