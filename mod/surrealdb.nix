{

  flake.modules.nixos.surrealdb =
    { lib, pkgs, ... }:
    {

      services.surrealdb = {
        enable = true;
      };

    };
}
