{ inputs, ... }: {
  flake = { ... }:
    let
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
        overlays = (import ../overlays.nix { inherit inputs; })
          ++
          (
            (
              (import ../hosts/lib.nix {
                inherit inputs;
              }).genOverlays
            ) [ "self" "clansty" "fenix" "berberman" "nvfetcher" "EHfive" "nuenv" "typst" "android-nixpkgs" ])
          ++ (with inputs; [ nur.overlay ]); #（>﹏<）
      };
    in
    {
      homeConfigurations =
        inputs.nixpkgs.lib.genAttrs [ "riro" "elen" ] (user:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home.nix
              inputs.hyprland.homeManagerModules.default
              inputs.android-nixpkgs.hmModule
            ];
            extraSpecialArgs = { inherit inputs user; };
          }
        );
    };
}
