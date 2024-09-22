{
  withSystem,
  self,
  inputs,
  ...
}:

withSystem "x86_64-linux" (
  _ctx@{
    config,
    inputs',
    system,
    ...
  }:
  let
    inherit (self) lib;
  in
  lib.nixosSystem {
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };
      overlays =
        (import "${self}/overlays.nix" { inherit inputs' inputs; })
        ++ (self.lib.genOverlays [
          "self"
          "fenix"
          "nuenv"
          "agenix-rekey"
          "berberman"
        ]);
    };
    specialArgs = {
      inherit
        lib
        self
        inputs
        inputs'
        ;
      inherit (config) packages;
      inherit (lib) data;
      user = "riro";
    };
    modules =
      lib.sharedModules
      ++ [
        ./hardware.nix
        ./network.nix
        ./rekey.nix
        ./spec.nix
        ./caddy.nix
        # ./nginx.nix
        # ../graphBase.nix

        ../persist.nix
        ../secureboot.nix
        ../../packages.nix
        ../../misc.nix
        ../sysvars.nix
        ../../age.nix

        ../sysctl.nix
        ../pam.nix
        ../virt.nix

        inputs.niri.nixosModules.niri
        ../../users.nix

        ./misskey.nix
        ../dev.nix
      ]
      ++ (with inputs; [
        aagl.nixosModules.default
        disko.nixosModules.default
        # niri.nixosModules.niri
        # nixos-cosmic.nixosModules.default
        # inputs.j-link.nixosModule
      ]);
  }
)
