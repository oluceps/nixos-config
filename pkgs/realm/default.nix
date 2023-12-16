{ lib
, fetchFromGitHub
, pkgs
}:

let
  rustPlatform = pkgs.makeRustPlatform { inherit (pkgs.fenix.minimal) cargo rustc; };
in

rustPlatform.buildRustPackage rec{
  pname = "realm";
  version = "2.5.0";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "zhboner";
    repo = pname;
    hash = "sha256-x3w4SMqglr64zVPN8r+IIR7jjPVKUHE6R9Obd3rPUTA=";
  };

  cargoHash = "sha256-QQGeGuGPZh5zAfPZx+EKJmxg8M2vfDuluX+ph7X8kx4=";

  RUSTC_BOOTSTRAP = 1;

  meta = with lib; {
    homepage = "https://github.com/zhboner/realm";
    description = "A network relay tool";
    mainProgram = "realm";
  };
}
