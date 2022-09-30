{ inputs, system, ... }:

let
  nixosSystem = inputs.nixpkgs.lib.nixosSystem;

  pkgs = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        nur-pkgs = inputs.nur-pkgs.packages."${prev.system}";
      })
      inputs.nur.overlay
    ] ++ (import ../overlay.nix inputs);

  };

  sharedModules = [
    ../misc.nix
    ../users.nix
    ../boot.nix
    ../packages.nix
    ../sysvars.nix
    ../modules
    {
      environment.systemPackages = [
        inputs.alejandra.defaultPackage.${system}
        inputs.agenix.defaultPackage.x86_64-linux
      ];
    }
  ] ++ (with inputs;[

    agenix.nixosModule
    grub2-themes.nixosModule
    home-manager.nixosModules.home-manager

  ]);
in
{
  hastur = nixosSystem {
    inherit system pkgs;
    specialArgs = { inherit inputs; };
    modules = (import ./hastur) ++ sharedModules;
  };

  kaambl = nixosSystem {
    inherit system pkgs;
    specialArgs = { inherit inputs; };
    modules = (import ./kaambl) ++ sharedModules;
  };
}
