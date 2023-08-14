{ inputs, self, ... }:

let
  lib = inputs.nixpkgs.lib;

  # I don't like this
  genModules = map (let m = i: inputs.${i}.nixosModules; in (i: (m i).default or (m i).${i}));

  sharedModules = [
    ../misc.nix
    ../users.nix
    ../packages.nix
    ../sysvars.nix
    ../services.nix
  ] ++ (genModules [ "agenix-rekey" "ragenix" "home-manager" "impermanence" "lanzaboote" "nix-ld" "self" ])
  ++ [ inputs.dae.nixosModules.dae ];

  data = {
    keys = {
      hashedPasswd = "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
      hasturHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
      kaamblHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ8LFIGiv5IEqra7/ky0b0UgWdTGPY1CPA9cH8rMnyf";
      ageKey = "age1jr2x2m85wtte9p0s7d833e0ug8xf3cf8a33l9kjprc9vlxmvjycq05p2qq";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
    };
  };

  fund = { inherit inputs lib data; };

  nixosSystem = lib.nixosSystem;

  genSysAttr = { system ? pkgs.stdenv.hostPlatform.system, user, hostname, pkgs }:
    rec {
      inherit system pkgs;
      specialArgs = fund // { inherit system user; };
      modules = (import ./${hostname}) ++ sharedModules;
    };

  genGeneralSys = i: nixosSystem (genSysAttr i);

in

{
  flake = { pkgs, ... }:
    let
      generalPkgs =
        system: import inputs.nixpkgs rec {
          inherit system;
          config = {
            # contentAddressedByDefault = true;
            allowUnfree = true;
            allowBroken = false;
            segger-jlink.acceptLicense = true;
            allowUnsupportedSystem = true;
            permittedInsecurePackages = pkgs.lib.mkForce [ ];
          };
          overlays = (import ../overlays.nix { inherit inputs system; })
            ++ (
            let genOverlays = map (let m = i: inputs.${i}.overlays; in (i: (m i).default or (m i).${i}));
            in (genOverlays [ "self" "clansty" "fenix" "berberman" "nvfetcher" "EHfive" "nuenv" "typst" "android-nixpkgs" ])
          )
            ++ (with inputs;[ nur.overlay ]); #（>﹏<）

        };
    in
    {
      _module.args.pkgs = generalPkgs "x86_64-linux";
      nixosConfigurations = {
        hastur = genGeneralSys {
          inherit pkgs;
          user = "riro";
          hostname = "hastur";
        };

        kaambl = genGeneralSys {
          inherit pkgs;
          user = "elen";
          hostname = "kaambl";
        };

        livecd =
          let
            inherit pkgs;
            user = "nixos";
            hostname = "livecd";
          in
          nixosSystem
            ((genSysAttr { inherit user hostname pkgs; })
              //
              {
                modules =
                  (import ./${hostname})
                    ++ (import ./${hostname}/additions.nix
                    (fund // { inherit user pkgs; }));
              });
      };
    };
}
