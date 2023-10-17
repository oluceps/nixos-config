{ inputs, genOverlays, sharedModules, base, lib, data, ... }:
[
  (import
    ./hastur
    { inherit genOverlays sharedModules base lib; })
  (import
    ./kaambl
    { inherit genOverlays sharedModules base lib; })

  ({ ... }: {
    flake = { pkgs, ... }: {
      colmena = {
        meta = {
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config = {
              allowUnfree = true;
              allowBroken = false;
            };
            overlays = (import ../overlays.nix { inherit inputs; })
              ++
              (genOverlays [
                "self"
                # "clansty"
                "fenix"
                "berberman"
                "nvfetcher"
                "EHfive"
                "nuenv"
                "agenix-rekey"
              ]);
          };
        };

        yidhra = { pkgs, ... }:
          let user = "elen"; in {
            deployment = {
              targetHost = "ls";
            };

            imports =
              (map (n: ./yidhra + ("/" + n)) [
                "hardware.nix"
                "network.nix"
                "spec.nix"
                "packages.nix"
              ]) ++

              (
                let a = { inherit data lib user; }; in [
                  (import ./yidhra/rekey.nix data)
                  (import ../age.nix a)
                  (import ../users.nix ({ inherit pkgs; } // a))
                ]
              )
              ++ sharedModules;
          };
      };
    };

  })
  ./livecd
]
