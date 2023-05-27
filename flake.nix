{
  description = "oluceps' flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-gui.url = "github:NixOS/nixpkgs?rev=954a801cbe128e24e78230f711df17da01a5d98c";
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nvfetcher.url = "github:berberman/nvfetcher";
    # eunomia-bpf.url = "github:eunomia-bpf/eunomia-bpf/flake-devenv";
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

  outputs = { self, nixpkgs, ... }@inputs:
    let
      genSystems = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];

      genOverlays = map (let m = i: inputs.${i}.overlays; in (i: (m i).default or (m i).${i})); # ugly

      _pkgs = genSystems (system: import nixpkgs {
        inherit system;
        config = {
          # contentAddressedByDefault = true;
          allowUnfree = true;
          allowBroken = false;
          segger-jlink.acceptLicense = true;
          allowUnsupportedSystem = true;
          permittedInsecurePackages = nixpkgs.lib.mkForce [ ];
        };
        overlays = (import ./overlays.nix { inherit inputs system; })
          ++ genOverlays [ "self" "clansty" "fenix" "berberman" "nvfetcher" ]
          ++ [ inputs.nur.overlay ]; #（>﹏<）
      });

      genericImport = p: import p { inherit inputs _pkgs; };
    in
    {
      nixosConfigurations = genericImport ./hosts;

      devShells.x86_64-linux = genericImport ./shells.nix;

      apps =
        genSystems (system: inputs.agenix-rekey.defineApps self _pkgs.${system}
          {
            inherit (self.nixosConfigurations)
              hastur kaambl;
          });

      overlays.default =
        final: prev: prev.lib.genAttrs (with builtins;(attrNames (readDir ./pkgs)))
          (name: final.callPackage (./pkgs + "/${name}") { });

      nixosModules = import ./modules { lib = inputs.nixpkgs.lib; };

      checks = genSystems (system: with _pkgs.${system};
        {
          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run
            {
              src = lib.cleanSource ./.;
              hooks = { nixpkgs-fmt.enable = true; };
            };
        });

    };

}
