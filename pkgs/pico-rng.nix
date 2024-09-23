{
  kernel,
  stdenv,
  fetchFromGitHub,
  cmake,
  pico-sdk,
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
  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ cmake ];
  makeFlags = kernel.makeFlags ++ [
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];
  # cmakeFlags = [
  #   "-DPICO_SDK_PATH=${pico-sdk}/lib/pico-sdk"
  # ];
  installPhase = ''
    install -D pico_rng.ko $out/lib/modules/${kernel.modDirVersion}/driver/pico_rng.ko
  '';
})
