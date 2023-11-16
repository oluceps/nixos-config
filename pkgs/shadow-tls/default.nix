{ fetchFromGitHub
, pkgs
, rustPlatform
}:

let
  rustPlatform = pkgs.makeRustPlatform { inherit (pkgs.fenix.minimal) cargo rustc; };
in
rustPlatform.buildRustPackage rec{
  pname = "shadow-tls";
  version = "0.2.23-unstable";

  src = fetchFromGitHub {
    rev = "3f4d3124b665b62d5bac44025a2781c729612a2a";
    owner = "ihciah";
    repo = pname;
    hash = "sha256-XMoNCSSj76aGJzGatOudwWO21qimlgeRMGNUmzxzM6I=";
  };
  RUSTC_BOOTSTRAP = 1;
  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "monoio-0.1.3" = "sha256-UEm+Zj86k7CTQO7gjmqeM2ajyp9UwBQ+t7UGi97oJuw=";
    };
  };
}
