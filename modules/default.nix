# ref: EHfive/flakes
{ lib, ... }:
let
  modules = lib.genAttrs
    [
      "ss"
      "rathole"
      "clash-m"
      "tuic"
      "btrbk"
      "naive"
      "sundial"
      "dae"
      "mosdns"
      "cn-up"
    ]
    (n: import (./. + ("/" + n))) //
  # Hysteria configs
  lib.genAttrs

    [
      "hyst-az"
      "hyst-do"
      # "hyst-am"
    ]
    (import ./hysteria)
  // { sing-box = import ./sing-box { }; };

  default = { ... }: {
    imports = builtins.attrValues modules;
  };
in
modules // { inherit default; }
