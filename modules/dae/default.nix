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
      configFile = config.rekey.secrets.dae.path;
      assets = "${pkgs.geos}/share/v2ray";
      dae = lib.getExe cfg.package;
      # See https://github.com/daeuniverse/dae/issues/43
      # NICComp = pkgs.writeShellScriptBin "nicComp" ''
      #   #!/usr/bin/env bash
      #   iface=$(${pkgs.iproute2}/bin/ip route | ${pkgs.lib.getExe pkgs.gawk} '/default/ {print $5}')
      #   ${pkgs.lib.getExe pkgs.ethtool} -K $iface tx-checksum-ip-generic off
      # '';

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
          "libvirtd.service"
          "systemd-sysctl.service"
        ];
        wants = [
          "network-online.target"
          "systemd-networkd-wait-online.service"
        ];
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
          Restart = "on-abnormal";
        };
      };
    };
}

