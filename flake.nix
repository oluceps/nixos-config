{
  description = "a nixos flake";
  outputs = inputs:
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
            overlays = [ inputs.nur.overlay ]
              ++ (import ./overlay.nix { inherit inputs system; })

              # overlays defined by others
              ++ map (i: (n: inputs.${n}.overlays.default) i)
              [
                "fenix"
                "berberman"
              ];
          }
        );
    in
    {
      nixosConfigurations = (import ./hosts { inherit inputs _pkgs; });

      devShells = genSystems (system:
        let
          pkgs = _pkgs.${system};
        in
        import ./shells.nix { inherit system pkgs inputs; }
      );

      overlays.default = final: prev:
        let
          dirContents = builtins.readDir ./pkgs;
          names = builtins.attrNames dirContents;
        in
        builtins.genAttrs names (name:
          final.callPackage (./pkgs + "/${name}") { }
        );

    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nixpkgs-pin-kernel.url = "github:NixOS/nixpkgs/master";
    nil.url = "github:oxalica/nil";
    nix-direnv.url = "github:nix-community/nix-direnv";
    nix-colors.url = "github:misterio77/nix-colors";
    agenix.url = "github:ryantm/agenix";
    nur.url = "github:nix-community/NUR";
    nur-pkgs = {
      url = "github:oluceps/nur-pkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
    };

    surrealdb = {
      url = "github:surrealdb/surrealdb";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    clash-meta = {
      url = "github:MetaCubeX/Clash.Meta/Alpha";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra";
    };

    polymc.url = "github:PolyMC/PolyMC";
    prismlauncher.url = "github:PrismLauncher/PrismLauncher";

    sops-nix.url = "github:Mic92/sops-nix";

    pywmpkg = {
      url = "github:jbuchermn/pywm";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
    };

    helix = {
      url = "github:helix-editor/helix";
    };

    hyprland = {
      url = "github:vaxerski/Hyprland";
    };
    #
    gomod2nix = {
      url = "github:tweag/gomod2nix";
    };
    grub2-themes.url = "github:vinceliuice/grub2-themes";

    mach-nix.url = "mach-nix/3.5.0";

    colmena.url = "github:zhaofengli/colmena";

    berberman = {
      url = "github:berberman/flakes";
    };

    # dream2nix.url = "github:nix-community/dream2nix";

  };

}
