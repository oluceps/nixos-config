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
      # buildInputs = with pkgs; [ jetbrains.pycharm-professional ];
      name = "python env";
    };

  kernel =
    (pkgs.buildFHSUserEnv {
      name = "kernel-build-env";
      targetPkgs = pkgs: (with pkgs;
        [
          dpkg
          pkgconfig
          pkg-config
          ncurses
          qt5.qtbase
          pkgsCross.mipsel-linux-gnu.stdenv.cc
          # pkgsCross.ppc64.stdenv.cc
          bison
          flex
          openssl.dev
          pahole
          bear
        ]
        ++ pkgs.linux.nativeBuildInputs);
      runScript = pkgs.writeScript "init.sh" ''
        # export ARCH=powerpc
        # export CROSS_COMPILE=powerpc64-unknown-linux-gnuabielfv2-
        export ARCH=mips
        export CROSS_COMPILE=mipsel-unknown-linux-gnu-
        export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:${pkgs.qt5.qtbase.dev}/lib/pkgconfig"
        export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins"
        export QT_QPA_PLATFORMTHEME=qt5ct
        exec bash
      '';
    }).env;

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
      newlib-nano
      zlib
      bison
      flex
      bc
      elfutils
      libbfd
      cmake

    ];
  };
  rv =
    let
      # more platforms are defined here: https://github.com/NixOS/nixpkgs/blob/master/lib/systems/examples.nix
      riscv64 = pkgs.pkgsCross.riscv64;
    in
    riscv64.linux.overrideAttrs (old: {
      # the override is optional if you need for example more build dependencies
      nativeBuildInputs = old.nativeBuildInputs ++ (with pkgs;[
        ncurses # tools/kwboot
        bc
        bison
        dtc
        flex
        openssl
        (buildPackages.python3.withPackages (p: [
          p.libfdt
          p.setuptools # for pkg_resources
        ]))
        swig
        which
      ]);
      shellHook = ''
        export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:${pkgs.qt5.qtbase.dev}/lib/pkgconfig"
      '';

    });


  mips =
    let
      # more platforms are defined here: https://github.com/NixOS/nixpkgs/blob/master/lib/systems/examples.nix
      pkg = pkgs.pkgsCross.mipsel-linux-gnu;
    in
    pkg.mkShell {
      # the override is optional if you need for example more build dependencies
      nativeBuildInputs = with pkgs; [
        ncurses # tools/kwboot
        bc
        bison
        dtc
        flex
        openssl.dev
        openssl_1_1
        swig
        which
      ] ++ [ pkg.openssl.dev ];
      shellHook = ''
        export PKG_CONFIG_PATH="${pkgs.ncurses6.dev}/lib/pkgconfig:${pkgs.qt5.qtbase.dev}/lib/pkgconfig"
        export ARCH=mips
        export CROSS_COMPILE=mipsel-unknown-linux-gnu-
      '';
    };



  ml =
    pkgs.mkShell
      {

        nativeBuildInputs = [
          pkgs.cudatoolkit
          (inputs.mach-nix.lib.${system}.mkPython {
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
        name = "machine learning";
      };

  android =
    let
      fhs = pkgs.buildFHSUserEnv {
        name = "android-build-env";
        targetPkgs = pkgs: with pkgs;
          [
            git
            gitRepo
            gnupg
            python2
            curl
            procps
            openssl
            gnumake
            nettools
            # For nixos < 19.03, use `androidenv.platformTools`
            androidenv.androidPkgs_9_0.platform-tools
            jdk
            schedtool
            util-linux
            m4
            gperf
            perl
            libxml2
            zip
            unzip
            bison
            flex
            lzop
            python3
          ];
        multiPkgs = pkgs: with pkgs;
          [
            zlib
            ncurses5
          ];
        runScript = "bash";
        profile = ''
          export ALLOW_NINJA_ENV=true
          export USE_CCACHE=1
          export ANDROID_JAVA_HOME=${pkgs.jdk.home}
          export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
        '';
      };
    in
    pkgs.stdenv.mkDerivation {
      name = "android-env-shell";
      nativeBuildInputs = [ fhs ];
      shellHook = "exec android-env";

    };

  openwrt =
    let
      fixWrapper = pkgs.runCommand "fix-wrapper" { } ''
        mkdir -p $out/bin
        for i in ${pkgs.gcc.cc}/bin/*-gnu-gcc*; do
          ln -s ${pkgs.gcc}/bin/gcc $out/bin/$(basename "$i")
        done
        for i in ${pkgs.gcc.cc}/bin/*-gnu-{g++,c++}*; do
          ln -s ${pkgs.gcc}/bin/g++ $out/bin/$(basename "$i")
        done
      '';

      fhs = pkgs.buildFHSUserEnv {
        name = "openwrt-build-env";
        targetPkgs = pkgs: with pkgs; [
          git
          perl
          gnumake
          gcc
          unzip
          util-linux
          python2
          python3
          .6
          rsync
          patch
          wget
          file
          subversion
          which
          pkg-config
          openssl
          fixWrapper
          systemd
          binutils

          ncurses
          zlib
          zlib.static
          glibc.static
        ];
        multiPkgs = null;
        extraOutputsToInstall = [ "dev" ];
        profile = ''
          export hardeningDisable=all
        '';
      };
    in
    fhs.env;

  ubt-rv = pkgs.mkShell {
    name = "riscv ubuntu qemu boot script";
    shellHook = ''
      qemu-system-riscv64 \
        -machine virt -nographic -m 4096 -smp 22 \
        -bios ${pkgs.pkgsCross.riscv64.opensbi}/share/opensbi/lp64/generic/firmware/fw_jump.elf \
        -kernel ${pkgs.pkgsCross.riscv64.ubootQemuRiscv64Smode}/u-boot.bin \
        -device virtio-net-device,netdev=usernet \
        -netdev user,id=usernet,hostfwd=tcp::12056-:22 \
        -device qemu-xhci -usb -device usb-kbd -device usb-tablet \
        -drive file=/var/lib/libvirt/images/ubuntu-22.10-preinstalled-server-riscv64+unmatched.img,format=raw,if=virtio
    '';
  };

  eunomia = pkgs.llvmPackages_14.libcxxStdenv.mkDerivation {
    name = "eunomia-dev";
    nativeBuildInputs = with pkgs; [
      cmake
      zlib
      pkg-config
      elfutils
      openssl.dev
      llvmPackages_14.llvm

      libbfd
      libcap
    ];
    LIBCLANG_PATH = "${pkgs.llvmPackages_14.libclang.lib}/lib";
  };

}
