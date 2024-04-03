{ lib, pkgs, ... }@args:

with lib;
let
  allSrvPath = (lib.subtractLists [ "default.nix" ] (with builtins; attrNames (readDir ./.)));

  allSrvPathNoSuffix = map (removeSuffix ".nix") allSrvPath;

  existSrvPath = filter (n: builtins.hasAttr n args.config.services) allSrvPathNoSuffix;
in
{
  options.srv = genAttrs allSrvPathNoSuffix (sn: mkEnableOption "${sn} service");

  config.services = genAttrs existSrvPath (
    n:
    (mkIf (args.config.srv.${n}) (
      import ./${n}.nix {
        inherit (args)
          pkgs
          config
          inputs
          lib
          user
          ;
      }
    ))
  );
}
