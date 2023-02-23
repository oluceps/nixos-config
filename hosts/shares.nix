{ inputs, system, pkgs }:
[
  ../misc.nix
  ../users.nix
  ../packages.nix
  ../sysvars.nix
  ../services.nix
  {
    environment.systemPackages = with inputs;
      [
        alejandra.defaultPackage.${system}
        agenix.packages.${system}.default
        helix.packages.${system}.default
        # surrealdb.packages.${system}.default
      ]
      ++ (with pkgs;[
        # (fenix.complete.withComponents [
        #   "cargo"
        #   "clippy"
        #   "rust-src"
        #   "rustc"
        #   "rustfmt"
        # ])
        rust-analyzer-nightly
      ])
    ;
  }
] ++ (with inputs;[

  agenix.nixosModules.default
  grub2-themes.nixosModules.default
  home-manager.nixosModules.home-manager
  impermanence.nixosModules.impermanence
  lanzaboote.nixosModules.lanzaboote
]) ++ (import ../modules)
