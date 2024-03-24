{ stdenv, fetchFromGitHub }:
stdenv.mkDerivation (finalAttrs: {
  name = "flake.nix"; # use dae pkg
  src = (import
    (
      let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
      fetchTarball {
        url = lock.nodes.flake-compat.locked.url or "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
        sha256 = lock.nodes.flake-compat.locked.narHash;
      }
    )
    {
      src = fetchFromGitHub {
        owner = "daeuniverse";
        repo = finalAttrs.name;
        rev = "9e021a7885ea7737337956e4ce8d553ba60bbdd0";
        hash = "sha256-0ysbxz9wbRnHWYL2I5101FwDI/sMwdmwQrG+GuInVqY=";
      };
    }
  ).defaultNix.packages.x86_64-linux.dae;

  installPhase = ''
    install -D $src/bin/dae $out/bin/dae
  '';
})


