{
  description = "a nixos flake";
  outputs = inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = (
        import ./hosts {
          inherit inputs system;
        }
      );

    };

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
    nix-colors.url = github:misterio77/nix-colors;
    agenix.url = github:ryantm/agenix;
    nur.url = github:nix-community/NUR;
    nur-pkgs = {
      url = github:oluceps/nur-pkgs;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    
    clash-meta = {
      url = github:MetaCubeX/Clash.Meta/Alpha;
    };

    alejandra = {
      url = github:kamadorueda/alejandra;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    polymc.url = github:PolyMC/PolyMC;
    sops-nix.url = github:Mic92/sops-nix;

    pywmpkg = {
      url = github:jbuchermn/pywm;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = github:nix-community/home-manager/master;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };


    nix-matlab = {
      # Recommended if you also override the default nixpkgs flake, common among
      # nixos-unstable users:
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = gitlab:doronbehar/nix-matlab;
    };

    helix = {
      url = github:helix-editor/helix;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    hyprland = {
      url = github:vaxerski/Hyprland;
      # build with your own instance of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    #
    gomod2nix = {
      url = github:tweag/gomod2nix;
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    grub2-themes.url = github:vinceliuice/grub2-themes;

    mach-nix.url = "mach-nix/3.5.0";
  };

}
