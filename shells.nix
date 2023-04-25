{ inputs, system, _pkgs }:
let pkgs = _pkgs.x86_64-linux; in {

  kernel =
    (pkgs.buildFHSUserEnv {
      name = "kernel-build-env";
      targetPkgs = pkgs: (with pkgs;
        [
          pkgconfig
          pkg-config
          ncurses
          qt5.qtbase
          # pkgsCross.mipsel-linux-gnu.stdenv.cc
          # pkgsCross.ppc64.stdenv.cc
          pkgsCross.aarch64-multiplatform.stdenv.cc
          # python2
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
        export ARCH=arm64
        export CROSS_COMPILE=aarch64-linux-android-
        export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig:${pkgs.qt5.qtbase.dev}/lib/pkgconfig"
        export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins"
        export QT_QPA_PLATFORMTHEME=qt5ct
        exec bash
      '';
    }).env;

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

  eunomia = with pkgs;mkShell {
    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
    ];

    buildInputs = [
      openssl
      pkgsStatic.zlib
      elfutils
      zlib
      stdenv
    ];
  };
}
