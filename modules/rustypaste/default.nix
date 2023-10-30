{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.rustypaste;
  settingsFormat = pkgs.formats.toml { };
in
{
  options.services.rustypaste = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.rustypaste;
    };
    settings = mkOption {
      type = settingsFormat.type;
      default = { };
    };
  };
  config =
    mkIf cfg.enable {
      systemd.services.rustypaste = {
        after = [ "network-online.target" ];
        description = "pastebin";

        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package}";
          StateDirectory = "paste";
          Environment = "CONFIG=${settingsFormat.generate "config.toml" cfg.settings}";
          Restart = "on-failure";
        };
      };
    };
}