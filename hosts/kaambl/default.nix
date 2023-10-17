{ sharedModules
, base
, genOverlays
, lib
}:
{ inputs, ... }: {
  flake = { pkgs, ... }:
    {
      nixosConfigurations = {
        kaambl = lib.nixosSystem
          {
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
                (genOverlays [
                  "self"
                  # "clansty"
                  "fenix"
                  "berberman"
                  "nvfetcher"
                  "EHfive"
                  "nuenv"
                  "typst"
                  "android-nixpkgs"
                  "agenix-rekey"
                ])
                ++ (with inputs;[ nur.overlay ]); #（>﹏<）
            };
            specialArgs = base // { user = "elen"; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix
              ../persist.nix
              ../secureboot.nix
              ../../services.nix
              ../../home
              ../../boot.nix
              ../../age.nix
              ../../packages.nix
              ../../misc.nix
              ../../users.nix
              ../../sysvars.nix
            ] ++ sharedModules;
          };
      };
    };
}
