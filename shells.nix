{ inputs, system, pkgs }:
{
  default =
    pkgs.mkShell {

      nativeBuildInputs = [
        (inputs.mach-nix.lib.${system}.mkPython
          {
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
          })
      ];
      buildInputs = with pkgs; [ jetbrains.pycharm-professional ];
      name = "pythonEnv";
    };

  general = pkgs.mkShell {
    name = "generalEnv";
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

    ];
  };

  ml = pkgs.mkShell {

    nativeBuildInputs = [
      pkgs.cudatoolkit
      (inputs.mach-nix.lib.${system}.mkPython rec
      {
        requirements = ''
          torch
          numpy
          albumentations
          opencv
          pudb
          invisible-watermark
          imageio
          imageio-ffmpeg
          pytorch-lightning
          omegaconf
          test-tube
          einops
          torch-fidelity
          transformers
          torchmetrics
          kornia
        '';
        providers = {
          # disallow wheels by default
          _default = "nixpkgs,sdist,wheel";
          # allow wheels only for torch
          torch = "wheel";
        };
      }
      )
    ];
    buildInputs = with pkgs; [ jetbrains.pycharm-professional ];
    name = "pythonEnv";
  };
}
