{
  pkgs,
  config,
  inputs,
  lib,
  user,
}:


  lib.genAttrs (with builtins; attrNames (readDir ./.)) (
    p:
    import p {
      inherit
        pkgs
        config
        inputs
        lib
        user
        ;
    }
  )

