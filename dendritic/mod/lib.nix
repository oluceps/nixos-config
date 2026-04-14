{
  flake-parts-lib,
  lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (args: {
    options.fn = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Helper functions for system configuration";
    };
  });
}
