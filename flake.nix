{
  description = "oluceps' flake";
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = import ./hosts {
        inherit inputs;
        inherit (import ./hosts/lib.nix inputs)
          genOverlays sharedModules base lib data self;
      };
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { pkgs, system, inputs', ... }: {

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = with inputs;[
            agenix-rekey.overlays.default
          ];
        };

        checks = with pkgs;
          {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run
              {
                src = lib.cleanSource ./.;
                hooks = { nixpkgs-fmt.enable = true; };
              };
          };

        devShells.default = with pkgs; mkShell {
          packages = [ agenix-rekey ];
        };

      };

      flake = {

        agenix-rekey = inputs.agenix-rekey.configure {
          userFlake = inputs.self;
          nodes = with inputs.nixpkgs.lib;
            filterAttrs (n: _: !elem n [ "nixos" ]) inputs.self.nixosConfigurations
          ;
        };

        overlays = {
          default =
            final: prev: prev.lib.genAttrs
              (with builtins;
              (with prev.lib; attrNames (
                filterAttrs (n: _: !elem n [ "ubt-rv-run" ]) # temporary disable pkg
                  (readDir ./pkgs))))
              (name: final.callPackage (./pkgs + "/${name}") { });

          lib = final: prev: (import ./hosts/lib.nix inputs);
        };

        nixosModules = import ./modules { lib = inputs.nixpkgs.lib; };
      };
    };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-pin.url = "github:NixOS/nixpkgs?rev=e7f38be3775bab9659575f192ece011c033655f0";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-gui.url = "github:NixOS/nixpkgs?rev=954a801cbe128e24e78230f711df17da01a5d98c";
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nixpkgs-rebuild.url = "github:SuperSandro2000/nixpkgs?rev=449114c6240520433a650079c0b5440d9ecf6156";
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    conduit = {
      url = "gitlab:famedly/conduit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun.url = "github:Kirottu/anyrun";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
    };
    # path:/home/riro/Src/flake.nix
    dae.url = "github:daeuniverse/flake.nix?rev=e16931c97e18eddd6a36b182687701cd6d03b284";
    # nixyDomains.url = "/home/elen/nixyDomains";
    nixyDomains.url = "github:oluceps/nixyDomains";
    nvfetcher.url = "github:berberman/nvfetcher";
    nuenv.url = "github:DeterminateSystems/nuenv";
    EHfive.url = "github:EHfive/flakes";
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    resign.url = "github:oluceps/resign";
    nil.url = "github:oxalica/nil";
    nix-direnv.url = "github:nix-community/nix-direnv";
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    misskey = {
      url = "github:Ninlives/misskey.nix";
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
    typst-lsp.url = "github:nvarner/typst-lsp";
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
    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    helix.url = "github:helix-editor/helix";
    hyprland.url = "github:vaxerski/Hyprland";
    berberman.url = "github:berberman/flakes";
    # clansty.url = "github:clansty/flake";
  };

}
