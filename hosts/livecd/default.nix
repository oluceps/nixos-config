{ inputs, ... }: {
  flake = { pkgs, ... }:
    let
      inherit (import ../lib.nix inputs) base;
    in
    {
      nixosConfigurations = {
        nixos = inputs.nixpkgs.lib.nixosSystem
          {
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
