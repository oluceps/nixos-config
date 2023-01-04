{ lib, stdenvNoCC, tdesktop, fetchFromGitHub }:
let
  version = "1.0.58";
  pname = "TDesktop-x64";
in
tdesktop.overrideAttrs
  (oldAttrs: {
    inherit pname version;
    src = fetchFromGitHub {
      owner = "TDesktop-x64";
      repo = "tdesktop";
      rev = "v${version}";
      fetchSubmodules = true;
      sha256 = "sha256-4svRa1hiPDZNUkKxUj+7uOe/6AoyP4OUFC8rss8QhGs=";
    };
    # cmakeFlags = oldAttrs.cmakeFlags ++ [
    #   "-DDESKTOP_APP_DISABLE_WAYLAND_INTEGRATION=ON"
    # ];
  })

