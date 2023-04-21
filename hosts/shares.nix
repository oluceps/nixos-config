{ inputs, system, pkgs }:
[
  ../misc.nix
  ../users.nix
  ../packages.nix
  ../sysvars.nix
  ../services.nix
  {
    environment.systemPackages =
      (with pkgs;[
        (fenix.complete.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
        ])
        # rust-analyzer-nightly
      ])
    ;
  }
] ++ (with inputs;[

  agenix-rekey.nixosModules.default
  ragenix.nixosModules.default
  grub2-themes.nixosModules.default
  home-manager.nixosModules.home-manager
  impermanence.nixosModules.impermanence
  lanzaboote.nixosModules.lanzaboote
]) ++ (import ../modules)
