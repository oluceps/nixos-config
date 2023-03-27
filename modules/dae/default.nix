{ pkgs
, config
, lib
, ...
}:
with lib;
let
  cfg = config.services.dae;
in
{
  options.services.dae = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.nur-pkgs.dae;
    };

  };
  config =
    let
      configFile = config.age.secrets.dae.path;
      assets = "${pkgs.geos}/share/v2ray";
      dae = lib.getExe cfg.package;
    in
    mkIf cfg.enable {
      networking.firewall = {
        allowedUDPPorts = [ 12345 ];
        allowedTCPPorts = [ 12345 ];
      };

      systemd.services.dae = {
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "docker.service"
          "systemd-sysctl.service"
        ];
        wants = [ "network-online.target" ];
        description = "Dae mon";

        serviceConfig = {
          Type = "notify";
          User = "root";
          LimitNPROC = 512;
          LimitNOFILE = 1048576;
          Environment = "DAE_LOCATION_ASSET=${assets}";
          ExecStartPre = "${dae} validate -c ${configFile}";
          ExecStart = "${dae} run --disable-timestamp -c ${configFile}";
          ExecReload = "${dae} reload $MAINPID";
          Restart = "on-failure";
        };
      };
    };
}

