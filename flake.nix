{
  description = "oluceps' flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-gui.url = "github:NixOS/nixpkgs?rev=954a801cbe128e24e78230f711df17da01a5d98c";
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nvfetcher.url = "github:berberman/nvfetcher";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    nil.url = "github:oxalica/nil";
    nix-direnv.url = "github:nix-community/nix-direnv";
    nix-colors.url = "github:misterio77/nix-colors";
    clansty.url = "github:clansty/flake";
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
    surrealdb.url = "github:surrealdb/surrealdb";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };
    impermanence.url = "github:nix-community/impermanence";
    clash-meta.url = "github:MetaCubeX/Clash.Meta/Alpha";
    alejandra.url = "github:kamadorueda/alejandra";
    polymc.url = "github:PolyMC/PolyMC";
    prismlauncher = {
      url = "github:PrismLauncher/PrismLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pywmpkg.url = "github:jbuchermn/pywm";
    home-manager.url = "github:nix-community/home-manager";
    helix.url = "github:helix-editor/helix";
    hyprland.url = "github:vaxerski/Hyprland";
    grub2-themes.url = "github:vinceliuice/grub2-themes";
    mach-nix.url = "mach-nix/3.5.0";
    colmena.url = "github:zhaofengli/colmena";
    berberman.url = "github:berberman/flakes";
  };

  outputs = { self, ... }@inputs:
    let
      genSystems = inputs.nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
      _pkgs = genSystems
        (
          system:
          import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowBroken = false;
              segger-jlink.acceptLicense = true;
              allowUnsupportedSystem = true;
              permittedInsecurePackages = [
                "python-2.7.18.6"
                "electron-21.4.0"
              ];
            };
            overlays =
              (with inputs; [
                nur.overlay
                clansty.overlays.clansty
              ])
              ++ (import ./overlays.nix { inherit inputs system; })

              # overlays defined by others
              # format to [ inputs.${user}.overlays.default ]
              ++ map (i: inputs.${i}.overlays.default)
                [
                  "self"
                  "fenix"
                  "berberman"
                  "nvfetcher"
                ];
          }
        );
    in
    {
      nixosConfigurations = import ./hosts { inherit inputs _pkgs; };

      devShells = genSystems (system: import ./shells.nix { inherit inputs system _pkgs; });

      apps =
        genSystems
          (system: inputs.agenix-rekey.defineApps self _pkgs.${system}
            { inherit (self.nixosConfigurations) hastur kaambl; });

      overlays.default =
        final: prev:
        let
          dirContents = builtins.readDir ./pkgs;
          names = builtins.attrNames dirContents;
        in
        prev.lib.genAttrs names (name: final.callPackage (./pkgs + "/${name}") { });

      checks = genSystems (system: with _pkgs.${system}; {
        pre-commit-check =
          inputs.pre-commit-hooks.lib.${system}.run
            {
              src = lib.cleanSource ./.;
              hooks = {
                nixpkgs-fmt.enable = true;
              };
            };
      });

    };

}
