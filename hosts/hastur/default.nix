{ sharedModules
, base
, genOverlays
, lib
}:
{ inputs, ... }: {
  flake = { pkgs, ... }:

    {
      nixosConfigurations = {
        hastur = inputs.nixpkgs.lib.nixosSystem
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
                  "typst"
                  "android-nixpkgs"
                  "dae"
                  "agenix-rekey"
                  "misskey"
                  "nixyDomains"
                ])
                ++ (with inputs;[ nur.overlay ]); #（>﹏<）
            };
            specialArgs = base // { user = "riro"; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix
              ./matrix.nix

              ../persist.nix
              ../secureboot.nix
              ../../packages.nix
              ../../services.nix
              ../../misc.nix
              ../../sysvars.nix
              ../../age.nix

              ../../boot.nix
              ../../home
              ../../users.nix

              inputs.misskey.nixosModules.default
              ./misskey.nix

            ] ++ sharedModules;
          };
      };
    };
}
