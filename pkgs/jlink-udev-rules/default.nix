{ stdenv
}:
## Usage
# In NixOS, simply add this package to services.udev.packages:
#   services.udev.packages = [ pkgs.opensk-udev-rules ];
stdenv.mkDerivation (finalAttrs: {
  pname = "jlink-udev-rules";

  version = "1";
  src = ./.;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -D ${finalAttrs.src}/rule $out/lib/udev/rules.d/99-jlink.rules
    runHook postInstall
  '';

})

