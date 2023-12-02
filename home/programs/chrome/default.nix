_:
{

  programs =
    let
      commandLineArgs = [ "--enable-wayland-ime" "--ozone-platform=wayland" ];
      # let commandLineArgs = [ "--gtk-version=4" "--ozone-platform=wayland" "--disable-features=WaylandFractionalScaleV1" ];
    in
    {
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
  
