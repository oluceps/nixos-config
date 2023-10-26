{ self, inputs, genOverlays, sharedModules, base, lib, data, ... }:
let share = { inherit genOverlays sharedModules base lib; }; in [
  (import
    ./hastur
    share)
  (import
    ./kaambl
    share)

  ./livecd

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
                "nixyDomains"
              ]);
          };
        };

        yidhra = { pkgs, nodes, ... }:
          let user = "elen"; in {
            deployment = {
              targetHost = "lsa";
            };

            imports =
              (map (n: ./yidhra + ("/" + n)) [
                "hardware.nix"
                "network.nix"
                "spec.nix"
              ]) ++

              (
                let a = { inherit data lib user; }; in [
                  (import ./yidhra/rekey.nix data)
                  (import ../age.nix a)
                  (import ../users.nix ({ inherit pkgs; } // a))
                  (import ../packages.nix (
                    ({
                      inherit pkgs;
                      inherit (base) self lib;
                      config = nodes.yidhra.config;
                    })
                  ))
                ]
              )
              ++ sharedModules;
          };

        azasos = { pkgs, nodes, ... }:
          let user = "elen"; in {
            deployment = {
              targetHost = "tcs";
            };

            imports =
              (map (n: ./azasos + ("/" + n)) [
                "hardware.nix"
                "network.nix"
                "spec.nix"
              ]) ++

              (
                let a = { inherit data lib user; }; in [
                  (import ./azasos/rekey.nix data)
                  (import ../age.nix a)
                  (import ../users.nix ({ inherit pkgs; } // a))
                  (import ../packages.nix (
                    ({
                      inherit pkgs;
                      inherit (base) self lib;
                      config = nodes.azasos.config;
                    })
                  ))
                ]
              )
              ++ sharedModules;
          };
      };
    };

  })
]
