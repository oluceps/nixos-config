{
  description = "flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nixpkgs-pin-kernel.url = "github:NixOS/nixpkgs/master";
    nil.url = "github:oxalica/nil";
    nix-direnv.url = "github:nix-community/nix-direnv";
    nix-colors.url = "github:misterio77/nix-colors";
    clansty.url = "github:clansty/flake";
    agenix = {
      url = "github:ryantm/agenix";
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
      inputs.nixpkgs.follows = "nixpkgs";
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
              ];
            };
            overlays =
              (with inputs; [
                nur.overlay
                clansty.overlays.clansty
                self.overlay
              ])
              ++ (import ./overlays.nix { inherit inputs system; })

              # overlays defined by others
              # format to [ inputs.${user}.overlays.default ]
              ++ map (i: inputs.${i}.overlays.default)
                [
                  "fenix"
                  "berberman"
                ];
          }
        );
    in
    {
      nixosConfigurations = (import ./hosts { inherit inputs _pkgs; });

      devShells = genSystems
        (system: import ./shells.nix { inherit system inputs; pkgs = _pkgs.${system}; });

      overlay = self.overlays.default;
      overlays.default = final: prev:
        let
          dirContents = builtins.readDir ./pkgs;
          names = builtins.attrNames dirContents;
        in
        prev.lib.genAttrs names (name: final.callPackage (./pkgs + "/${name}") { });

    };

}
