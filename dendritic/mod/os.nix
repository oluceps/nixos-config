{
  inputs,
  lib,
  config,
  ...
}:
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      name:
      { module }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          module
          (config.flake.modules.nixos."age/${name}" or { }) # secret accompany with host
        ];
      }
    );

    # checks =
    #   config.flake.nixosConfigurations
    #   |> lib.mapAttrsToList (
    #     name: nixos: {
    #       ${nixos.config.nixpkgs.hostPlatform.system} = {
    #         "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
    #       };
    #     }
    #   )
    #   |> lib.mkMerge;
  };
}
