{ lib, ... }:
{
  flake.modules.nixos.autosign =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.repack.autosign;
      # readToStore takes a path relative to constant.nix's location typically,
      # but let's check how it's defined in constant.nix.
      # readToStore = p: toString (pkgs.writeTextFile { name = baseNameOf p; text = builtins.readFile p; });
      # We need an absolute path or relative to THIS file if we use builtins.readFile.
      scriptPath = config.fn.readToStore ../../../script/autosign.ts;
    in
    {
      options.repack.autosign = {
        enable = lib.mkEnableOption "autosign";
        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
      config = lib.mkIf cfg.enable {
        systemd.user.timers = {
          autosign = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "*-*-* 13:13:00";
              RandomizedDelaySec = "1h";
              Persistent = true;
            };
          };
        };
        systemd.user.services.autosign = {
          description = "autosign Daemon";
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.deno} run --allow-env --allow-net --no-check ${scriptPath}";
            EnvironmentFile = cfg.environmentFile;
            Environment = [ "HOME=/home/${config.identity.user}" ];
            Restart = "on-failure";
            RestartSec = "20s";
            RestartSteps = "5";
            RestartMaxDelaySec = "2h";
            StartLimitBurst = 5;
          };
        };
      };
    };
}
