{ lib, pkgs, ... }@args:
let

  inherit (lib)
    subtractLists
    foldr
    filter
    removeSuffix
    ;

  allSrvPath = (subtractLists [ "default.nix" ] (with builtins; attrNames (readDir ../srv)));

  allSrvName = map (removeSuffix ".nix") allSrvPath;

  # process attach attr, with enable or not
  A = map (n: import ../srv/${n} args) allSrvPath;

  C = filter (n: args.config.services.${n}.enable) allSrvName;
in
{
  config = foldr (acc: elem: acc // A.${elem}.attach or { }) { } allSrvName;
}
