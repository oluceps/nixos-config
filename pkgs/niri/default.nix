{ lib
, rustPlatform
, libglvnd
, fetchFromGitHub
, autoPatchelfHook
, pkg-config
, libxkbcommon
, pipewire
, seatd
, udev
, wayland
, stdenv
, libinput
, mesa
}:

rustPlatform.buildRustPackage {
  pname = "niri";
  version = "unstable-2023-10-31";

  src = fetchFromGitHub {
    owner = "YaLTeR";
    repo = "niri";
    rev = "86c4c1368e3ca2e01d7179e5fb86f8c4bdbe2cc4";
    hash = "sha256-sUKWPOQUgIyTGLQd02aFn8Ab6gOKfdoilS81S1mSwhY=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "smithay-0.3.0" = "sha256-Eqs4wqogdld6MHOXQ2NRFCgJH4RHf4mYWFdjRVUVxsk=";
    };
  };
  nativeBuildInputs = [
    pkg-config
    autoPatchelfHook
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    wayland
    udev
    seatd # For libseat
    libxkbcommon
    libinput
    mesa # For libgbm
    stdenv.cc.cc.lib
    pipewire
  ];

  runtimeDependencies = [
    wayland
    mesa
    libglvnd # For libEGL
  ];


}
