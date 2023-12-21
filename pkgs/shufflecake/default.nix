{ lib, kernel, stdenv, fetchFromGitea, libgcrypt, lvm2 }:
let
  genShufflecake = name: installPhase:
    stdenv.mkDerivation (finalAttrs: {
      inherit name;
      version = "0.4.3";
      src = fetchFromGitea {
        domain = "codeberg.org";
        owner = "shufflecake";
        repo = "shufflecake-c";
        rev = "v${finalAttrs.version}";
        hash = "sha256-aBLa0puoOrrsJAFSFANtQr3oH/HXAZ809rQeBC4nHxs=";
      };

      nativeBuildInputs = kernel.moduleBuildDependencies;
      buildInputs = [ libgcrypt lvm2 ];
      makeFlags = kernel.makeFlags ++ [
        "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        "INSTALL_MOD_PATH=$(out)"
      ];
      inherit installPhase;

      meta = with lib; {
        description = "A plausible deniability (hidden storage) layer for Linux";
        homepage = "https://shufflecake.net";
        license = licenses.gpl2Only;
        maintainers = with maintainers; [ oluceps ];
      };
    });

in
(builtins.mapAttrs (name: value: genShufflecake name value) {
  shufflecake-c = "install -D dm-sflc.ko $out/lib/modules/${kernel.modDirVersion}/misc/dm-sflc.ko";
  shufflecake = "install -D shufflecake $out/bin/shufflecake";
})
