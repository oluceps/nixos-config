{ inputs, system, user, ... }:


let
  homeProfile = ./home.nix;
in
{
  home-manager = {
    useGlobalPkgs = true;
    # useUserPackages = true;
    users.${user} = {
      imports = [
        homeProfile
        inputs.hyprland.homeManagerModules.default
        ../modules/hyprland
        #        
      ];
    };
    extraSpecialArgs = { inherit inputs system user; };
  };

}
