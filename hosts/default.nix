{ inputs, _pkgs }:
let
  lib = inputs.nixpkgs.lib;
  nixosSystem = lib.nixosSystem;

  # I don't like this
  genModule = e: map (i: inputs.${i}.nixosModules.${e});
  genModuleGen = map (i: inputs.${i}.nixosModules.${i});
  sharedModules = pkgs:
    [
      ../misc.nix
      ../users.nix
      ../packages.nix
      ../sysvars.nix
      ../services.nix
      {
        environment.systemPackages =
          (with pkgs;[ (fenix.complete.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ]) ]);
      }
    ] ++
    (genModule "default" [ "agenix-rekey" "ragenix" ])
    ++
    (genModuleGen [ "home-manager" "impermanence" "lanzaboote" ])
    ++ (import ../modules);

  genSysAttr = { system, user, hostname }:
    rec {
      inherit system;
      pkgs = _pkgs.${system};
      specialArgs = { inherit inputs system user lib; };
      modules = (import ./${hostname})
        ++ sharedModules pkgs;
    };

  genGeneralSys = a:
    nixosSystem (genSysAttr { inherit (a) system user hostname; });

in
{
  hastur = genGeneralSys {
    system = "x86_64-linux";
    user = "riro";
    hostname = "hastur";
  };

  kaambl = genGeneralSys {
    system = "x86_64-linux";
    user = "elena";
    hostname = "kaambl";
  };

  livecd =
    let
      system = "x86_64-linux";
      user = "nixos";
      hostname = "livecd";
      pkgs = _pkgs.${system};
    in
    nixosSystem
      ((genSysAttr { inherit system user hostname; })
        //
        {
          modules =
            (import ./${hostname})
              ++ (import ./${hostname}/additions.nix { inherit inputs user pkgs; });
        });
}
