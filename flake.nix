{
  description = "a nixos flake";
  outputs = inputs:
    let
      genSystems = inputs.nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
      system = inputs.flake-utils.lib.system;
      pkgss = genSystems
        (
          system:
          import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowBroken = false;
              segger-jlink.acceptLicense = true;
              allowUnsupportedSystem = true;
            };
            overlays = [
              (final: prev: {
                nur-pkgs = inputs.nur-pkgs.packages."${system}";
              })

              inputs.nur.overlay

              inputs.fenix.overlays.default

              inputs.nix-matlab.overlay

              inputs.berberman.overlays.default

            ] ++ (import ./overlay.nix inputs);
          }
        );
    in
    {
      nixosConfigurations = (
        import ./hosts {
          inherit inputs pkgss;
        }
      );

      devShells = genSystems (system:
        let
          pkgs = pkgss.${system};
        in
        import ./shells.nix { inherit system pkgs inputs; }
      );

      overlays.oluceps = final: prev:
        let
          dirContents = builtins.readDir ./modules/packs;
          genPackage = name: {
            inherit name;
            value = final.callPackage (./packages + "/${name}") { };
          };
          names = builtins.attrNames dirContents;
        in
        builtins.listToAttrs (map genPackage names);

    };

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    nixpkgs-22.url = "github:NixOS/nixpkgs?rev=c91d0713ac476dfb367bbe12a7a048f6162f039c";
    nil.url = github:oxalica/nil;
    flake-utils.url = github:numtide/flake-utils;
    nix-colors.url = github:misterio77/nix-colors;
    agenix.url = github:ryantm/agenix;
    nur.url = github:nix-community/NUR;
    nur-pkgs = {
      url = github:oluceps/nur-pkgs;
    };

    rnix-lsp.url = github:nix-community/rnix-lsp;

    fenix = {
      url = github:nix-community/fenix;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpicker = {
      url = github:hyprwm/hyprpicker;
    };

    surrealdb = {
      url = github:surrealdb/surrealdb;
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    impermanence.url = github:nix-community/impermanence;

    clash-meta = {
      url = github:MetaCubeX/Clash.Meta/Alpha;
    };

    alejandra = {
      url = github:kamadorueda/alejandra;
    };

    polymc.url = github:PolyMC/PolyMC;
    prismlauncher.url = github:PrismLauncher/PrismLauncher;

    sops-nix.url = github:Mic92/sops-nix;

    pywmpkg = {
      url = github:jbuchermn/pywm;
    };

    home-manager = {
      url = github:nix-community/home-manager;
    };


    nix-matlab = {
      # Recommended if you also override the default nixpkgs flake, common among
      # nixos-unstable users:
      url = gitlab:doronbehar/nix-matlab;
    };

    helix = {
      url = github:helix-editor/helix;
    };

    hyprland = {
      url = github:vaxerski/Hyprland;
    };
    #
    gomod2nix = {
      url = github:tweag/gomod2nix;
    };
    grub2-themes.url = github:vinceliuice/grub2-themes;

    mach-nix.url = "mach-nix/3.5.0";

    colmena.url = github:zhaofengli/colmena;

    berberman = {
      url = github:berberman/flakes;
    };
  };

}
