{ pkgs, lib, ... }:

pkgs.rustPlatform.buildRustPackage {
  pname = "shpool-mux";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-0/2tqEt+y7jXwdDJreQEVBEsyQQXPNgJ9AI6vyjdGhM=";

  cargoHash = "sha256-0/2tqEt+y7jXwdDJreQEVBEsyQQXPNgJ9AI6vyjdGhM=";
}
