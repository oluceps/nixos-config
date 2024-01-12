{ lib
, fetchFromGitHub
, pkgs
}:

let
  rustPlatform = pkgs.makeRustPlatform { inherit (pkgs.fenix.minimal) cargo rustc; };
in

rustPlatform.buildRustPackage rec{
  pname = "restls";
  version = "0.1.1";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "3andne";
    repo = pname;
    hash = "";
  };

  cargoHash = "";

  # RUSTC_BOOTSTRAP = 1;
}
