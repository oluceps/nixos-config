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

    txChecksumIpGeneric = mkOption {
      type = types.bool;
      default = false;
    };

  };
  config =
    let
      configFile = config.age.secrets.dae.path;
      assets = "${pkgs.geos}/share/v2ray";
      dae = lib.getExe cfg.package;
      # See https://github.com/daeuniverse/dae/issues/43
      NICComp = pkgs.writeShellApplication {
        name = "nicComp";
        text = with pkgs; ''
          iface=$(${iproute2}/bin/ip route | ${lib.getExe gawk} '/default/ {print $5}')
          ${lib.getExe ethtool} -K "$iface" tx-checksum-ip-generic off
        '';
      };

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
          ExecStartPre = [ "${dae} validate -c ${configFile}" ]
            ++ (with lib; optional cfg.txChecksumIpGeneric (getExe NICComp));
          ExecStart = "${dae} run --disable-timestamp -c ${configFile}";
          ExecReload = "${dae} reload $MAINPID";
          Restart = "on-abnormal";
        };
      };
    };
}

