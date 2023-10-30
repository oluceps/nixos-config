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
                permittedInsecurePackages = inputs.nixpkgs.lib.mkForce [ "electron-24.8.6" ];
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
                  "android-nixpkgs"
                  "agenix-rekey"
                  "nixyDomains"
                  "nixpkgs-wayland"
                ]);
              # ++ (with inputs;[ nur.overlay ]); #（>﹏<）
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
            ]
            ++ sharedModules
            ++
            [ inputs.home-manager.nixosModules.default ];
          };
      };
    };
}
