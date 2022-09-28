with import <nixpkgs> { }; 
pkgsCross.arm-embedded.stdenv.mkDerivation {
name = "env";
  # nativeBuildInputs is usually what you want -- tools you need to run
  nativeBuildInputs = with pkgs; [

    llvmPackages_latest.bintools.all
    openssl_1_1
    openssl.dev
    pkg-config
    ncurses
    cargo-fuzz
    rustup
    newlib-nano
    #    binutils-unwrapped-all-targets

    (
      let
        mach-nix = import
          (builtins.fetchGit {
            url = "https://github.com/DavHau/mach-nix";
            ref = "refs/tags/3.5.0";
          })
          { };
      in
      mach-nix.mkPython {
        requirements = ''
          pillow
          dbus-python
          numpy
          redis
          testresources
          requests
          uvloop
          adafruit-nrfutil


          fido2
          tockloader == 1.5.0
          intelhex
          colorama
          tqdm
          cryptography

          pandas
          requests
          pyrogram
          tgcrypto
          JPype1
          toml
          pyyaml
          tockloader
          colorama
          six
        '';
      }
    )
  ];
 }
