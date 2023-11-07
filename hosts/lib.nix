inputs: rec {

  # I don't like this
  genModules = map (let m = i: inputs.${i}.nixosModules; in (i: (m i).default or (m i).${i}));

  genOverlays = map (let m = i: inputs.${i}.overlays; in (i: (m i).default or (m i).${i}));

  sharedModules = [
  ] ++ (genModules [ "agenix-rekey" "ragenix" "impermanence" "lanzaboote" "nix-ld" "self" ])
  ++ (with inputs.dae.nixosModules;[ dae daed ]);

  data = {
    keys = {
      hashedPasswd = "$y$j9T$dQkjYyrZxZn1GnoZLRRLE1$nvNuCnEvJr9235CX.VXabEUve/Bx00YB5E8Kz/ewZW0";
      hasturHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
      kaamblHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ8LFIGiv5IEqra7/ky0b0UgWdTGPY1CPA9cH8rMnyf";
      yidhraHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2EINWqn8MoL0tzM1j3PlWQoDydVqKjqQZn0eg+CzVq";
      nodensHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcsSxaMn3hbiIvoHTWyVVTUZ5UjqUAmGlAwdiFmX/ey";
      azasosHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcPj9kBLOvdQXPqZbCY/PxZQ7MOqdzDyo1UQuCwbk0l";
      ageKey = "age1jr2x2m85wtte9p0s7d833e0ug8xf3cf8a33l9kjprc9vlxmvjycq05p2qq";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
    };

    withoutHeads = [ "azasos" "nodens" "yidhra" ];
  };

  base = let lib = inputs.nixpkgs.lib; in { inherit inputs lib data; inherit (inputs) self; };
}
