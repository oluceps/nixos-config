{
  description = "oluceps' flake";
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = import ./hosts inputs;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { pkgs, system, inputs', ... }: {

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = with inputs;[
            agenix-rekey.overlays.default
            fenix.overlays.default
            self.overlays.default
          ];
        };

        checks = with pkgs; {
          pre-commit-check =
            inputs.pre-commit-hooks.lib.${system}.run {
              src = lib.cleanSource ./.;
              hooks = { nixpkgs-fmt.enable = true; };
            };
        };

        devShells.default = with pkgs; mkShell {
          packages = [ agenix-rekey home-manager just ];
        };

        packages = with pkgs.lib; genAttrs
          (with builtins; (attrNames (
            filterAttrs
              (n: _: !elem n [
                "glowsans" # multi pkgs
                "opulr-a-run" # ?
                "tcp-brutal" # kernelModule
                "shufflecake"
              ])
              (readDir ./pkgs))))
          (n: pkgs.${n});
      };

      flake = {

        agenix-rekey = inputs.agenix-rekey.configure {
          userFlake = inputs.self;
          nodes = with inputs.nixpkgs.lib;
            filterAttrs (n: _: !elem n [ "nixos" "bootstrap" ]) inputs.self.nixosConfigurations
          ;
        };

        overlays = {
          default =
            final: prev: prev.lib.genAttrs
              (with builtins;
              (with prev.lib; attrNames (
                filterAttrs
                  (n: _: !elem n [
                    "nobody"
                    "tcp-brutal"
                    "shufflecake"
                  ])
                  (readDir ./pkgs))))
              (name: final.callPackage (./pkgs + "/${name}") { });

          lib = final: prev: (import ./hosts/lib.nix inputs);
        };

        nixosModules = import ./modules { inherit (inputs.nixpkgs) lib; };
      };
    };

  inputs = {
    nixpkgs-factorio.url = "github:NixOS/nixpkgs?rev=b480f6f0b571abe201f6143d6d1f974049977259";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    conduit = {
      url = "gitlab:famedly/conduit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nyx = {
      # url = "/home/elen/Src/nyx";
      url = "github:oluceps/nyx";
    };
    factorio-manager = {
      url = "/home/elen/Src/factorio-manager";
      # url = "github:oluceps/nyx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv.url = "github:cachix/devenv";
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
    };
    # path:/home/riro/Src/flake.nix
    dae.url = "github:daeuniverse/flake.nix?rev=e16931c97e18eddd6a36b182687701cd6d03b284";
    # nixyDomains.url = "/home/elen/nixyDomains";
    nixyDomains.url = "github:oluceps/nixyDomains";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    helix.url = "github:helix-editor/helix";
    hyprland.url = "github:vaxerski/Hyprland";
    berberman.url = "github:berberman/flakes";
    # clansty.url = "github:clansty/flake";
  };

}
