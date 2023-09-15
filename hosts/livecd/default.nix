{ inputs, ... }: {
  flake = { pkgs, ... }:
    let
      inherit (import ../lib.nix { inherit inputs; }) lib base;
    in
    {
      nixosConfigurations = {
        nixos = lib.nixosSystem
          rec {
            pkgs = import inputs.nixpkgs {
              system = "x86_64-linux";
            };
            specialArgs = { user = "nixos"; };
            modules = [
            ]
            ++ (import ./additions.nix (base // { inherit pkgs; }));
          };
      };
    };
}
