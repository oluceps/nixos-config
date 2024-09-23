{
  kernel,
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "pico-rng";
  src = fetchFromGitHub {
    owner = "polhenarejos";
    repo = finalAttrs.name;
    rev = "f009dc267ce995761a4b5e0d3846af664aa094de";
    hash = "sha256-KvDSAlMSRhfPSKtpe4hjThoc3nSxsS2S2dQxga2owUk=";
  };

  sourceRoot = "${finalAttrs.src.name}/driver";
  # makeFlags = kernel.makeFlags ++ [
    # "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    # "INSTALL_MOD_PATH=$(out)"
  # ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out/src
    cp pico_rng.c $out/src
    cp Kbuild $out/src
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$out/src modules
    runHook postBuild
  '';
  nativeBuildInputs = kernel.moduleBuildDependencies;
  installPhase = ''
    install -D pico_rng.ko $out/lib/modules/${kernel.modDirVersion}/driver/pico_rng.ko
  '';
})
