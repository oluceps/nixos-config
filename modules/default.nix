# ref: EHfive/flakes
{ lib, ... }:
let
  modules = lib.genAttrs
    [
      "shadowsocks"
      "rathole"
      "clash-m"
      "tuic"
      "juicity"
      "btrbk"
      "naive"
      "sundial"
      "rustypaste"
      # "dae"
      "factorio"
      "hysteria"
      "mosdns"
      "realm"
      "phantomsocks"
      "scx"
      "test"
    ]
    (n: import (./. + ("/" + n)))
  // { sing-box = import ./sing-box { }; };

  default = { ... }: {
    imports = builtins.attrValues modules;
  };
in
modules // { inherit default; }
