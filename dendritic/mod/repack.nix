{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  repack-path = ../repack;
  repack-dir = builtins.readDir repack-path;
  repack-files = builtins.filter (n: n != "default.nix" && repack-dir.${n} == "regular") (
    builtins.attrNames repack-dir
  );
  repack-names = map (n: lib.removeSuffix ".nix" n) repack-files;
in
{
  flake.modules.nixos.repack = {
    options.repack = lib.genAttrs repack-names (name: {
      enable = lib.mkEnableOption "enable repacked ${name} module";
    });

    config = {
      repack = lib.genAttrs repack-names (name: {
        enable = lib.mkDefault false;
      });
    };

  };
}
