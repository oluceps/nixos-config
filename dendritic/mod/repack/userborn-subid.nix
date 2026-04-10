{ lib, ... }:
{
  flake.modules.nixos.userborn-subid =
    { config, lib, ... }:
    let
      cfg = config.repack.userborn-subid;
      entries =
        kindLetter:
        lib.concatLists (
          lib.mapAttrsToList (
            _: userCfg:
            lib.lists.map (
              rangeCfg: "${userCfg.name}:${toString rangeCfg."start${kindLetter}id"}:${toString rangeCfg.count}"
            ) userCfg."sub${kindLetter}idRanges"
          ) config.users.users
        );
      mkIdRangeFile = kindLetter: lib.concatLines (entries kindLetter) + "
";
      commonSettings = {
        mode = "0644"; # newuidmap open files using O_NOFOLLOW
      };
    in
    {
      options.repack.userborn-subid.enable = lib.mkEnableOption "userborn-subid";
      config = lib.mkIf cfg.enable {
        environment.etc."subuid" = commonSettings // {
          text = mkIdRangeFile "U";
        };
        environment.etc."subgid" = commonSettings // {
          text = mkIdRangeFile "G";
        };
      };
    };
}
