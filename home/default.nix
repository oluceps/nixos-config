{ self, inputs, ... }:
{
  flake = ({ ... }:
    let lib = inputs.nixpkgs.lib.extend self.overlays.lib; in
    {
      homeConfigurations = lib.genAttrs [ "elen" "riro" ]
        (user:
          inputs.home-manager.lib.homeManagerConfiguration (
            {
              pkgs = import inputs.nixpkgs {
                system = "x86_64-linux";
                config = {
                  permittedInsecurePackages = lib.mkForce [ "electron-24.8.6" ];
                  allowUnfree = true;
                };
                overlays = (import ../overlays.nix inputs)
                  ++
                  (lib.genOverlays [
                    "self"
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
                inputs.anyrun.homeManagerModules.default
                inputs.android-nixpkgs.hmModule
              ];
              extraSpecialArgs = { inherit inputs user; system = "x86_64-linux"; };
            }
          )
        );
    });
}
