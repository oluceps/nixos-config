{
  withSystem,
  self,
  inputs,
  ...
}:
let

  /*
    "hastur" # homeserver    # network censored
    "azasos" # tencent cloud # network censored
    "nodens" # digital ocean
    "yidhra" # aws lightsail
    "abhoth" # alicloud      # network censored
    "colour" # azure
    "eihort" # C222          # network censored
  */
  generalHost = [
    # "colour"
    "nodens"
    "kaambl"
    # "abhoth"
    "azasos"
    "eihort"
  ];
in
{
  flake = withSystem "x86_64-linux" (
    {
      config,
      inputs',
      system,
      ...
    }:
    {
      colmena =
        let
          inherit (self) lib;
        in
        {
          meta = {
            nixpkgs = import inputs.nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = [
                  "cinny-4.1.0"
                  "cinny-unwrapped-4.1.0"
                ];
                allowUnsupportedSystem = true;
              };
              overlays =
                (import ../overlays.nix { inherit inputs' inputs; })
                ++ (lib.genOverlays [
                  "self"
                  "fenix"
                  "nuenv"
                  "agenix-rekey"
                  "android-nixpkgs"
                  "berberman"
                  "attic"
                ]);
            };

            nodeNixpkgs = { };

            specialArgs = {
              inherit
                lib
                self
                inputs
                inputs'
                ;
              inherit (config) packages;
              inherit (lib) data;
            };

            nodeSpecialArgs =
              {
                hastur = {
                  user = "riro";
                };
              }
              // (lib.genAttrs generalHost (n: {
                user = "elen";
              }));
          };
        }
        // (lib.genAttrs (generalHost ++ [ "hastur" ]) (h: ./. + "/${h}"));
    }
  );
}
