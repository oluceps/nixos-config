{
  flake.modules.nixos.ntfy =
    { config, lib, ... }:
    {
      realm.workloads.ntfy = {
        unit = "ntfy-sh.service";
        user = "ntfy-sh";
        group = "ntfy-sh";
        isolation.runtimePaths = [ "/run/ntfy-sh" ];
        ingress = {
          http = {
            port = 12586;
            target = "127.0.0.1:2586";
            privateLoopback = true;
            service = "ntfy";
            allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
          };
          metrics = {
            port = 19099;
            target = "127.0.0.1:9099";
            privateLoopback = true;
            service = "ntfy-metrics";
            allowedIDs = [ "spiffe://nyaw.xyz/service/observability-${config.networking.hostName}" ];
          };
        };
        egress.internet = {
          service = "internet-proxy";
          verifyID = "spiffe://nyaw.xyz/service/internet";
          localPort = 13128;
        };
      };
      realm.workloads.caddy = lib.mkIf (config ? caddy) {
        egress.ntfy = {
          service = "ntfy";
          verifyID = "spiffe://nyaw.xyz/service/ntfy";
        };
      };
      realm.workloads.observability.egress.ntfy = {
        service = "ntfy-metrics";
        verifyID = "spiffe://nyaw.xyz/service/ntfy";
      };
      realm.observability.endpoints.ntfy.socket = "/run/realm/observability/egress/ntfy.sock";
      systemd.services.ntfy-sh = {
        environment = {
          HTTP_PROXY = "http://127.0.0.1:13128";
          HTTPS_PROXY = "http://127.0.0.1:13128";
          NO_PROXY = "localhost,127.0.0.1,::1";
        };
        serviceConfig = {
          AmbientCapabilities = lib.mkForce [ ];
          CapabilityBoundingSet = lib.mkForce [ ];
        };
      };
      services.ntfy-sh = {
        enable = true;
        settings = {
          listen-http = "127.0.0.1:2586";
          behind-proxy = true;
          auth-default-access = "deny-all";
          base-url = "http://ntfy.nyaw.xyz";
          enable-metrics = true;
          metrics-listen-http = "127.0.0.1:9099";
          auth-users = [
            "lyo:$2a$12$O8gSrfED8kHXOvdovr7lOew/gMfawvBKJdRUvaAiuR3vQOrm2aus2:admin"
            "phi:$2a$10$Nmlat8Qzx4ze8UcgBjzMGeGSq8b0smQ21F6bMC5d5Vs5AVFYJBUxC:user"
          ];
          auth-access = [
            "phi:broadcast:write-only"
            "*:broadcast:ro"
            "*:up*:rw"
          ];
        };
      };
    };
}
