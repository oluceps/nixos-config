{ inputs, _pkgs }:
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
  ] ++ (genModules [ "agenix-rekey" "ragenix" "home-manager" "impermanence" "lanzaboote" ]) ++ (import ../modules);

  data = {
    keys = {
      hashedPasswd = "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
      hasturHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
      kaamblHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1v1/CbbmzLxxlGLb9AQouo+8ID/puQYMfdIQTLgfV+";
      ageKey = "age1jr2x2m85wtte9p0s7d833e0ug8xf3cf8a33l9kjprc9vlxmvjycq05p2qq";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
    };
  };

  fund = { inherit inputs lib data; };

  nixosSystem = lib.nixosSystem;

  genSysAttr = { system, user, hostname }:
    rec {
      inherit system;
      pkgs = _pkgs.${system};
      specialArgs = fund // { inherit system user; };
      modules = (import ./${hostname}) ++ sharedModules;
    };

  genGeneralSys = i: nixosSystem (genSysAttr i);

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
              ++ (import ./${hostname}/additions.nix
              (fund // { inherit user pkgs; }));
        });
}
