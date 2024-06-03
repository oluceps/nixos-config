inputs:
let
  data = {
    keys = {
      hashedPasswd = "$y$j9T$dQkjYyrZxZn1GnoZLRRLE1$nvNuCnEvJr9235CX.VXabEUve/Bx00YB5E8Kz/ewZW0";
      hasturHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4XC7dGxwY7VUPr4t+NtWL+c7pTl8g568jdv6aRbhDZ";
      kaamblHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ8LFIGiv5IEqra7/ky0b0UgWdTGPY1CPA9cH8rMnyf";
      yidhraHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2EINWqn8MoL0tzM1j3PlWQoDydVqKjqQZn0eg+CzVq";
      nodensHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcsSxaMn3hbiIvoHTWyVVTUZ5UjqUAmGlAwdiFmX/ey";
      azasosHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJOhSRZCY7nGhwhW6VaYGsT2dqRn5pA9Ic20bQVn4GJ";
      abhothHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+Zc19g/x0M8nBhuM5xD5sTRYHHi4MzPEf/rdpTWCre";
      colourHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINuN2Twf8uZqM56i0CO9AZJZIZ8c8s2ytq7RzOMaGH4H";
      eihortHostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFnI3PehP4SUQkD1UZ7eMKlgxQiU9MDpbYjp+3wXnVA";
      ageKey = "age1jr2x2m85wtte9p0s7d833e0ug8xf3cf8a33l9kjprc9vlxmvjycq05p2qq";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
      skSshPubKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH+HwSzDbhJOIs8cMuUaCsvwqfla4GY6EuD1yGuNkX6QAAAADnNzaDoxNjg5NTQzMzc1";
    };
    xmrAddr = "83u3a1Sx8wt5hQ9o8eHoSbKDPRwt9uGLJ8b26GHzfZ3Ha17ASekNTMvQk7TnYEqL724UuWQrJbBq7Cvg1HHZqGQc7WsT8RV";
  };

  genModules = map (
    let
      m = i: inputs.${i}.nixosModules;
    in
    i: (m i).default or (m i).${i}
  );

  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    overlays = [ inputs.nuenv.overlays.default ];
  };
in
{
  inherit data genModules;

  genOverlays = map (i: inputs.${i}.overlays.default);

  sharedModules =
    [ ]
    ++ (genModules [
      "agenix-rekey"
      "ragenix"
      "impermanence"
      "lanzaboote"
      "catppuccin"
      "lix-module"
      "self"
    ])
    ++ (with inputs.dae.nixosModules; [
      dae
      daed
    ]);

  genFilteredDirAttrs =
    dir: excludes:
    inputs.nixpkgs.lib.genAttrs (
      let
        inherit (builtins)
          filter
          elem
          attrNames
          readDir
          ;
      in
      filter (n: !elem n excludes) (attrNames (readDir dir))
    );

  genFilteredDirAttrsV2 =
    dir: excludes:
    let
      inherit (inputs.nixpkgs.lib)
        genAttrs
        subtractLists
        removeSuffix
        attrNames
        filterAttrs
        ;
      inherit (builtins) readDir;
    in
    genAttrs (
      subtractLists excludes (
        map (removeSuffix ".nix") (attrNames (filterAttrs (_: v: v == "regular") (readDir dir)))
      )
    );

  genCredPath = config: key: (key + ":" + config.age.secrets.${key}.path);

  capitalize =
    str:
    let
      inherit (pkgs.lib.strings) toUpper substring concatStrings;
    in
    concatStrings [
      (toUpper (substring 0 1 str))
      (substring 1 16 str)
    ];

  readToStore =
    p:
    toString (
      pkgs.writeTextFile {
        name = builtins.baseNameOf p;
        text = builtins.readFile p;
      }
    );

  secCompLayer =
    secs:
    let
      inherit (pkgs.lib) mapAttrs writeText;
    in
    if !(builtins.pathExists "${inputs.self}/sec") then
      (mapAttrs (
        n: v:
        v
        // {
          rekeyFile = writeText "empty" ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IHNzaC1lZDI1NTE5IEdPMitlQSB3Wjgx
            ZHlSYWdyajZDc0Foek5DZkd6a25vdUcxL1F6UktoMk90a0o2YkVRCmc1cW40UU1G
            THZidFJCcVRSL1VTTzNHYlNIUGsvQ1d2bHpjWmg3QzVsRG8KLT4gcGl2LXAyNTYg
            ZlYxVlFBIEF1QUtPWHhseTdKUmlDRERIdkUzR1JnT1ArVExkcEVna1IzUGFJaDQr
            cmRkCkhaaTlZcERwblpFK0s3VUVYOUx3S00yckx1enBURVJMd0hFSkxZY09XdjgK
            LT4gIXtbby1ncmVhc2UKVWMrTzFhVlhyT2hHalFvCi0tLSBNbzNlVnpSa2dyYXNw
            dkxiQm9SQ2xJaXVTd25WSTFNMTduNk5RVnU4d1ZJCuP+oqFlibWZC4RE9t/t4lF/
            Psju+EG7Nj86x73RozGE
            -----END AGE ENCRYPTED FILE-----
          '';
        }
      ) secs)
    else
      secs;

  parent =
    let
      inherit (inputs.nixpkgs.lib)
        concatStringsSep
        reverseList
        splitString
        drop
        ;
    in
    p: concatStringsSep "/" (reverseList (drop 1 (reverseList (splitString "/" p))));
}
