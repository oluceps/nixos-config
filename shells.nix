{inputs, system, pkgs }:
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

}
