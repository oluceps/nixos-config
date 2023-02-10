{ inputs, pkgss }:
let
  nixosSystem = inputs.nixpkgs.lib.nixosSystem;
in
{
  hastur = nixosSystem (

    let
      system = "x86_64-linux";
      pkgs = pkgss.${system};
      user = "riro";
    in
    {
      inherit system pkgs;
      specialArgs = { inherit inputs system user; };
      modules = (import ./hastur) ++ (import ./shares.nix { inherit system pkgs inputs; });
    }
  );

  kaambl = nixosSystem (

    let
      system = "x86_64-linux";
      pkgs = pkgss.${system};
      user = "elena";
    in
    {
      inherit system pkgs;
      specialArgs = { inherit inputs system user; };
      modules = (import ./kaambl) ++ (import ./shares.nix { inherit system pkgs inputs; });
    }
  );

  livecd = nixosSystem (
    let
      user = "isho";
      system = "x86_64-linux";
      pkgs = pkgss.${system};
    in
    {
      inherit system pkgs;
      specialArgs = { inherit inputs system user; };
      modules = (import ./livecd) ++ (import ./shares.nix { inherit system pkgs inputs; }) ++
        [ (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel.nix") ]
      ;
    }
    # OMG 7.3G ISO 
  );
}
