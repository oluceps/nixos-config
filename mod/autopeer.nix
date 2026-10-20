{ inputs, ... }:
{
  flake.modules.nixos.autopeer =
    { config, lib, ... }:
    let
      cfg = config.services.autopeer;
    in
    {
      imports = [ inputs.autopeer.nixosModules.default ];
      realm.workloads.autopeer = {
        # WireGuard and nftables management require the host network/netlink.
        isolation = {
          privateNetwork = false;
          runtimePaths = [ cfg.birdConfDir ];
          allowUnixSockets = [
            "-/run/bird"
            "-/run/systemd/resolve"
          ];
        };
        ingress.http = {
          port = 19341;
          target = "127.0.0.1:${toString cfg.port}";
          hostLoopback = true;
          service = "autopeer-${config.networking.hostName}";
          allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
        };
        egress.postgresql = {
          service = "postgresql-autopeer";
          verifyID = "spiffe://nyaw.xyz/service/postgresql";
          socket = "/run/realm/autopeer/egress/.s.PGSQL.5432";
        };
      };
      realm.workloads.caddy = lib.mkIf (config ? caddy) {
        egress.autopeer = {
          service = "autopeer-${config.networking.hostName}";
          verifyID = "spiffe://nyaw.xyz/service/autopeer";
        };
      };
      # Upstream currently binds 0.0.0.0. Keep its API reachable only through
      # the authenticated ingress, including from otherwise trusted mesh links.
      networking.nftables.tables.realm-autopeer = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority -5; policy accept;
            iifname != "lo" tcp dport ${toString cfg.port} drop
          }
        '';
      };
      systemd.services.autopeer.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectProc = "invisible";
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
      };
    };
}
