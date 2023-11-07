{ sharedModules
, base
, genOverlays
}:
{ inputs, ... }: {
  flake = { pkgs, ... }:
    {
      nixosConfigurations = {
        yidhra = inputs.nixpkgs.lib.nixosSystem
          {
            pkgs = import inputs.nixpkgs {
              system = "x86_64-linux";
              config = {
                # contentAddressedByDefault = true;
              };
              overlays = (import ../../overlays.nix { inherit inputs; })
                ++
                (genOverlays [
                  "self"
                  "fenix"
                  "EHfive"
                  "nuenv"
                  "agenix-rekey"
                  "nixyDomains"
                  "nixpkgs-wayland"
                ]);
            };
            specialArgs = base // { user = "elen"; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix
              ../../age.nix
              ../../packages.nix
              ../../misc.nix
              ../../users.nix
            ]
            ++ sharedModules;
          };
      };
    };
}
