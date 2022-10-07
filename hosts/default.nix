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
    ../services.nix
    {
      environment.systemPackages = with inputs; [
        alejandra.defaultPackage.${system}
        agenix.defaultPackage.${system}
        helix.packages.${system}.default
      ];
    }
  ] ++ (with inputs;[

    agenix.nixosModule
    grub2-themes.nixosModule
    home-manager.nixosModules.home-manager

  ]) ++ (import ../modules);


in
{
  hastur = nixosSystem (
    let user = "riro"; in
    {
      inherit system pkgs;
      specialArgs = { inherit inputs system user; };
      modules = (import ./hastur) ++ sharedModules;
    }
  );

  kaambl = nixosSystem (
    let user = "elena"; in
    {
      inherit system pkgs;
      specialArgs = { inherit inputs system user; };
      modules = (import ./kaambl) ++ sharedModules;
    }
  );
}
