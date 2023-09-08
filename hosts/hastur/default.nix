{ inputs, ... }: {
  flake = { pkgs, ... }:
    let
      inherit (import ../lib.nix { inherit inputs; }) sharedModules base genOverlays;
      user = "riro";
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config = {
          # contentAddressedByDefault = true;
          allowUnfree = true;
          allowBroken = false;
          segger-jlink.acceptLicense = true;
          allowUnsupportedSystem = true;
          permittedInsecurePackages = inputs.nixpkgs.lib.mkForce [ ];
        };
        overlays = (import ../../overlays.nix { inherit inputs; })
          ++
          (genOverlays [ "self" "clansty" "fenix" "berberman" "nvfetcher" "EHfive" "nuenv" "typst" "android-nixpkgs" "dae" ])
          ++ (with inputs;[ nur.overlay ]); #（>﹏<）
      };
    in
    {
      nixosConfigurations = {
        hastur = inputs.nixpkgs.lib.nixosSystem
          {
            inherit pkgs;
            specialArgs = base // { inherit user; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix

              ../persist.nix
              ../secureboot.nix

              ../../boot.nix
            ] ++ sharedModules;
          };
      };
      # homeConfigurations.${user} =
      #   inputs.home-manager.lib.homeManagerConfiguration {
      #     inherit pkgs;
      #     modules = [ ../../home/home.nix ];
      #     extraSpecialArgs = { inherit inputs user; };
      #   };
    };
}
