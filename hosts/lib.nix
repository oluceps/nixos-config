{ inputs, ... }: rec {

  # I don't like this
  genModules = map (let m = i: inputs.${i}.nixosModules; in (i: (m i).default or (m i).${i}));

  sharedModules = [
    ../misc.nix
    ../age.nix
    ../users.nix
    ../sysvars.nix
    ../services.nix
  ] ++ (genModules [ "agenix-rekey" "ragenix" "home-manager" "impermanence" "lanzaboote" "nix-ld" "self" ])
  ++ (with inputs.dae.nixosModules;[ dae daed ]);

  data = {
    keys = {
      hashedPasswd = "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
      hasturHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
      kaamblHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ8LFIGiv5IEqra7/ky0b0UgWdTGPY1CPA9cH8rMnyf";
      yidhraHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMR/CIRf089P1oxLCfYdYVOMzmKlr/2O4aOFMQgrTdX";
      ageKey = "age1jr2x2m85wtte9p0s7d833e0ug8xf3cf8a33l9kjprc9vlxmvjycq05p2qq";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
    };
  };

  lib = inputs.nixpkgs.lib;

  base = { inherit inputs lib data; };

  genOverlays = map (let m = i: inputs.${i}.overlays; in (i: (m i).default or (m i).${i}));
}
