{ inputs, _pkgs }:
let
  nixosSystem = inputs.nixpkgs.lib.nixosSystem;

  genSysAttr = { system, user, hostname }:
    rec {
      inherit system;
      pkgs = _pkgs.${system};
      specialArgs = { inherit inputs system user; };
      modules = (import ./${hostname})
        ++ (import ./shares.nix { inherit inputs system pkgs; });
    };

  genGeneralSys = { ... }@a:
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
      o = (genSysAttr
        {
          system = "x86_64-linux";
          user = "isho";
          hostname = "livecd";
        });
    in
    nixosSystem (o // {
      modules = o.modules ++ [
        (inputs.nixpkgs
          + "/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix")
      ];
    });
}
