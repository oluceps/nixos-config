{ stdenv, fetchFromGitHub, lib }:
stdenv.mkDerivation (finalAttrs: {
  name = "flake.nix"; # use dae pkg
  src = (lib.legacyGetFlake {
    src = fetchFromGitHub {
      owner = "daeuniverse";
      repo = finalAttrs.name;
      rev = "9e021a7885ea7737337956e4ce8d553ba60bbdd0";
      hash = "sha256-0ysbxz9wbRnHWYL2I5101FwDI/sMwdmwQrG+GuInVqY=";
    };
  }).packages.x86_64-linux.dae;

  installPhase = ''
    install -D $src/bin/dae $out/bin/dae
  '';
})


