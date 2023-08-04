{
  description = "oluceps' flake";
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./hosts
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
        };
        apps = inputs.agenix-rekey.defineApps inputs.self pkgs
          {
            inherit (inputs.self.nixosConfigurations)
              hastur
              kaambl;
          };
        checks = with pkgs;
          {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run
              {
                src = lib.cleanSource ./.;
                hooks = { nixpkgs-fmt.enable = true; };
              };
          };
      };
      flake = {
        overlays.default =
          final: prev: prev.lib.genAttrs
            (with builtins;
            (with prev.lib; attrNames (
              filterAttrs (n: _: !elem n [ "ubt-rv-run" ]) # temporary disable pkg
                (readDir ./pkgs))))
            (name: final.callPackage (./pkgs + "/${name}") { });

        nixosModules = import ./modules { lib = inputs.nixpkgs.lib; };

      };
    };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-gui.url = "github:NixOS/nixpkgs?rev=954a801cbe128e24e78230f711df17da01a5d98c";
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nixpkgs-rebuild.url = "github:SuperSandro2000/nixpkgs?rev=449114c6240520433a650079c0b5440d9ecf6156";
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
    };
    dae.url = "github:daeuniverse/flake.nix";
    nixyDomains.url = "github:oluceps/nixyDomains";
    nvfetcher.url = "github:berberman/nvfetcher";
    nuenv.url = "github:DeterminateSystems/nuenv";
    EHfive.url = "github:EHfive/flakes";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    resign.url = "github:oluceps/resign";
    nil.url = "github:oxalica/nil";
    nix-direnv.url = "github:nix-community/nix-direnv";
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixified-ai.url = "github:nixified-ai/flake";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    typst.url = "github:typst/typst";
    nur-pkgs = {
      url = "github:oluceps/nur-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprpicker.url = "github:hyprwm/hyprpicker";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };
    impermanence.url = "github:nix-community/impermanence";
    clash-meta.url = "github:MetaCubeX/Clash.Meta/Alpha";
    alejandra.url = "github:kamadorueda/alejandra";
    polymc.url = "github:PolyMC/PolyMC";
    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    helix.url = "github:helix-editor/helix";
    hyprland.url = "github:vaxerski/Hyprland";
    berberman.url = "github:berberman/flakes";
    clansty.url = "github:clansty/flake";
  };

}
