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
              # targetHost = "nyaw.xyz";
              # targetPort = 22;
              # targetUser = user;
              targetHost = "ls";
            };

            imports =
              (map (n: ./yidhra + ("/" + n)) [
                "hardware.nix"
                "network.nix"
                "spec.nix"
                "packages.nix"
              ]) ++ [
                (import ./yidhra/rekey.nix data)
                (import ../age.nix { inherit data lib user; })
                (import ../users.nix { inherit pkgs data lib user; })
              ]
              ++ sharedModules;
          };
      };
    };

  })
  ./livecd
]
