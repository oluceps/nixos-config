# ref: EHfive/flakes
{ lib, ... }:
let
  modules = lib.genAttrs
    [
      "ss"
      "rathole"
      "clash-m"
      "tuic"
      "juicity"
      "btrbk"
      "naive"
      "sundial"
      "rustypaste"
      # "dae"
      "hysteria"
      "mosdns"
    ]
    (n: import (./. + ("/" + n)))
  // { sing-box = import ./sing-box { }; };

  default = { ... }: {
    imports = builtins.attrValues modules;
  };
in
modules // { inherit default; }
