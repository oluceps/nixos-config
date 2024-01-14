# ref: EHfive/flakes
{ lib, ... }:
let
  disabledModules = [ "polybar" "sing-box" ];

  modules =
    map (p: ./. + ("/" + p))
      (builtins.filter (e: !builtins.elem e [ "default.nix" ])
        (builtins.attrNames (builtins.readDir ./.)))
    // { sing-box = import ./sing-box { }; };

  default = { ... }: {
    imports = builtins.attrValues modules;
  };
in
modules // { inherit default; }
