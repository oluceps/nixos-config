{ inputs, ... }: {
  flake = { pkgs, ... }:
    let
      inherit (import ../lib.nix { inherit inputs; }) sharedModules base genOverlays;
    in
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
                permittedInsecurePackages = inputs.nixpkgs.lib.mkForce [ ];
              };
              overlays = (import ../../overlays.nix { inherit inputs; })
                ++
                (genOverlays [
                  "self"
                  "clansty"
                  "fenix"
                  "berberman"
                  "nvfetcher"
                  "EHfive"
                  "nuenv"
                  "typst"
                  "android-nixpkgs"
                  "dae"
                  "agenix-rekey"
                ])
                ++ (with inputs;[ nur.overlay ]); #（>﹏<）
            };
            specialArgs = base // { user = "riro"; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix

              ../persist.nix
              ../secureboot.nix

              ../../boot.nix
              ../../home
            ] ++ sharedModules;
          };
      };
    };
}
