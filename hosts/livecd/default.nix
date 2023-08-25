{ inputs, ... }: {
  flake = { pkgs, ... }:
    let
      inherit (import ../lib.nix { inherit inputs; }) lib;
    in
    {
      nixosConfigurations = {
        nixos = lib.nixosSystem
          {
            inherit pkgs;
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix
              ../persist.nix
              ../secureboot.nix
              ./home.nix
              ../../packages.nix
              (import ../../modules/sing-box { min = true; })
            ];
          };
      };
    };
}
