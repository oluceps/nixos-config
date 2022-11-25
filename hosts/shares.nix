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
        agenix.defaultPackage.${system}
        helix.packages.${system}.default
        surrealdb.packages.${system}.default

      ]
      ++ (with pkgs;[
        #        (fenix.complete.withComponents [
        #          "cargo"
        #          "clippy"
        #          "rust-src"
        #          "rustc"
        #          "rustfmt"
        #        ])
        rust-analyzer-nightly
      ]);
  }
] ++ (with inputs;[

  agenix.nixosModule
  grub2-themes.nixosModule
  home-manager.nixosModules.home-manager
#  impermanence.nixosModules.impermanence

]) ++ (import ../modules)
