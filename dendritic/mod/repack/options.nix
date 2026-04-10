{ lib, ... }:
{
  options.incus = {
    enable = lib.mkEnableOption "incus";
    user = lib.mkOption {
      type = lib.types.str;
      default = "riro";
    };
    bridgeAddr = lib.mkOption {
      type = lib.types.str;
      default = "fdcc:1::1/64";
    };
  };

  options.subs = {
    enable = lib.mkEnableOption "subs";
    scriptPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/private/subs/subs.ts";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "riro";
    };
  };

  options.photoprism = {
    enable = lib.mkEnableOption "photoprism";
  };
}
