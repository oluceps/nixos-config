{ self, inputs, ... }: {
  flake =
    let lib = inputs.nixpkgs.lib.extend self.overlays.lib; in
    {
      nixosConfigurations = {
        kaambl = inputs.nixpkgs.lib.nixosSystem
          {
            pkgs = import inputs.nixpkgs {
              system = "x86_64-linux";
              config = {
                # contentAddressedByDefault = true;
                allowUnfree = true;
                allowBroken = false;
                segger-jlink.acceptLicense = true;
                allowUnsupportedSystem = true;
                permittedInsecurePackages = lib.mkForce [ "electron-25.9.0" ];
              };
              overlays = (import ../../overlays.nix inputs)
                ++
                (lib.genOverlays [
                  "self"
                  # "clansty"
                  "fenix"
                  "berberman"
                  "EHfive"
                  "nuenv"
                  "android-nixpkgs"
                  "agenix-rekey"
                  "nixyDomains"
                  "nixpkgs-wayland"
                ]);
            };
            specialArgs = lib.base // { user = "elen"; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix
              ../persist.nix
              ../secureboot.nix
              ../../services.nix
              inputs.home-manager.nixosModules.default
              ../../home
              ../../boot.nix
              ../../age.nix
              ../../packages.nix
              ../../misc.nix
              ../../users.nix
              ../../sysvars.nix
            ]
            ++ lib.sharedModules
            ++
            [
              inputs.aagl.nixosModules.default
            ];
          };
      };
    };
}
