{ self, inputs, ... }: {

  flake = { ... }:
    let lib = inputs.nixpkgs.lib.extend self.overlays.lib; in
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
                permittedInsecurePackages = lib.mkForce [ "electron-24.8.6" ];
              };
              overlays = (import ../../overlays.nix inputs)
                ++
                (lib.genOverlays [
                  "self"
                  # "clansty"
                  "fenix"
                  "berberman"
                  "nvfetcher"
                  "EHfive"
                  "nuenv"
                  "android-nixpkgs"
                  "dae"
                  "agenix-rekey"
                  "misskey"
                  "nixyDomains"
                ])
                ++ (with inputs;[ nur.overlay ]); #（>﹏<）
            };
            specialArgs = lib.base // { user = "riro"; };
            modules = [
              ./hardware.nix
              ./network.nix
              ./rekey.nix
              ./spec.nix
              ./matrix.nix

              ../persist.nix
              ../secureboot.nix
              ../../packages.nix
              ../../services.nix
              ../../misc.nix
              ../../sysvars.nix
              ../../age.nix

              ../../boot.nix
              # ../../home
              ../../users.nix

              inputs.misskey.nixosModules.default
              ./misskey.nix

              ./vaultwarden.nix

            ] ++ lib.sharedModules;
          };
      };
    };
}
