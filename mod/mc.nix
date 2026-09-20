{
  flake.modules.nixos.mc =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      services.minecraft-servers = {
        enable = true;
        eula = true;
      };
    };
}
