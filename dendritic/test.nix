{
  description = "test multiple flake.modules";
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        ./mod/a.nix
        ./mod/b.nix
      ];
    };
}
