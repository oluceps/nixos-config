inputs:
let
  data = {
    keys = {
      hashedPasswd = "$y$j9T$dQkjYyrZxZn1GnoZLRRLE1$nvNuCnEvJr9235CX.VXabEUve/Bx00YB5E8Kz/ewZW0";
      hasturHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
      kaamblHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ8LFIGiv5IEqra7/ky0b0UgWdTGPY1CPA9cH8rMnyf";
      yidhraHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2EINWqn8MoL0tzM1j3PlWQoDydVqKjqQZn0eg+CzVq";
      nodensHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcsSxaMn3hbiIvoHTWyVVTUZ5UjqUAmGlAwdiFmX/ey";
      azasosHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcPj9kBLOvdQXPqZbCY/PxZQ7MOqdzDyo1UQuCwbk0l";
      abhothHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+Zc19g/x0M8nBhuM5xD5sTRYHHi4MzPEf/rdpTWCre";
      colourHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPggVBxIKKp1SmKoc0cyS0fka3uLH6xNmtBNLHlxQK0T";
      ageKey = "age1jr2x2m85wtte9p0s7d833e0ug8xf3cf8a33l9kjprc9vlxmvjycq05p2qq";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
      skSshPubKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH+HwSzDbhJOIs8cMuUaCsvwqfla4GY6EuD1yGuNkX6QAAAADnNzaDoxNjg5NTQzMzc1";
    };

    # azasos: in wall
    withoutHeads = [
      # "azasos" # tencent cloud
      "nodens" # digital ocean
      # "yidhra" # aws lightsail
      # "abhoth" # alicloud
      "colour" # azure
    ];
  };

  genModules = map (let m = i: inputs.${i}.nixosModules; in i: (m i).default or (m i).${i});
in
{
  inherit data genModules;

  genOverlays = map (i: inputs.${i}.overlays.default);

  sharedModules = [
  ] ++ (genModules [ "agenix-rekey" "ragenix" "impermanence" "lanzaboote" "nix-ld" "self" ])
  ++ (with inputs.dae.nixosModules;[ dae daed ]);

  genFilteredDirAttrs = dir: excludes:
    inputs.nixpkgs.lib.genAttrs
      (with builtins; filter
        (n: !elem n excludes)
        (attrNames
          (readDir dir)));
  base =
    let inherit (inputs.nixpkgs) lib;
    in { inherit inputs lib data; inherit (inputs) self; };
}
