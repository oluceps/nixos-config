{ self, inputs, ... }:
{
  flake = ({ ... }:
    let lib = inputs.nixpkgs.lib.extend self.overlays.lib; in
    {
      homeConfigurations.elen = inputs.home-manager.lib.homeManagerConfiguration (
        let user = "elen"; in {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config = {
              permittedInsecurePackages = lib.mkForce [ "electron-24.8.6" ];
              allowUnfree = true;
            };
            overlays = (import ../overlays.nix { inherit inputs; })
              ++
              (lib.genOverlays [
                "self"
                "fenix"
                "EHfive"
                "nuenv"
                "agenix-rekey"
                "android-nixpkgs"
                "nixyDomains"
                "nixpkgs-wayland"
                "berberman"
              ]);
          };
          modules = [
            (import ./home.nix user)
            inputs.hyprland.homeManagerModules.default
            inputs.android-nixpkgs.hmModule
          ];
          extraSpecialArgs = { inherit inputs; system = "x86_64-linux"; user = "elen"; };
        }
      );
    });
}
