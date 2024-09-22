{
  lib,
  config,
  pkgs,
  ...
}@args:
let
  repackNames = (
    map (lib.removeSuffix ".nix") (
      lib.attrNames (lib.filterAttrs (n: v: n != "default.nix") (builtins.readDir ./.))
    )
  );
  reIf = r: lib.mkIf config.repack.${r}.enable;
in
{
  options.repack = lib.genAttrs repackNames (n: {
    enable = lib.mkEnableOption "enable repacked ${n} module";
  });
  imports = map (n: import ./${n}.nix (args // { inherit reIf pkgs; })) repackNames;
}
