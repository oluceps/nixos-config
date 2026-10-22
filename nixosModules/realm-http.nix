{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.realm;
  clients = lib.filterAttrs (
    _: w: w.enable && (w.http.internet || w.http.internal != [ ])
  ) cfg.workloads;
  gatewayNames =
    domains:
    builtins.attrNames (
      lib.filterAttrs (
        _: gateway: lib.any (domain: lib.elem domain gateway.hosts) domains
      ) cfg.http.gateways
    );
in
{
  options.realm.http.gateways = mkOption {
    default = { };
    description = "Internal HTTPS gateways and the DNS names each gateway serves.";
    type = types.attrsOf (
      types.submodule {
        options = {
          hosts = mkOption { type = types.listOf types.str; };
          service = mkOption { type = types.str; };
          verifyID = mkOption { type = types.str; };
        };
      }
    );
  };

  options.realm.workloads = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        let
          w = config;
          gateways = gatewayNames w.http.internal;
        in
        {
          options.http = {
            internet = lib.mkEnableOption "HTTP Internet access through the Realm proxy";
            internal = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                Internal HTTPS names reached through a Realm gateway, without the Internet proxy.
                These names configure routing and proxy selection. The gateway authorizes access
                to its HTTPS listener, which can serve other names on the same listener.
              '';
            };
          };
          config = lib.mkMerge [
            (mkIf w.http.internet {
              egress.internet = {
                service = "internet-proxy";
                verifyID = "${cfg.servicePrefix}internet";
                localPort = 13128;
              };
            })
            (mkIf (w.http.internal != [ ]) {
              isolation.hosts = lib.genAttrs w.http.internal (_: "127.0.0.1");
              egress = lib.genAttrs (map (name: "http-${name}") gateways) (
                route:
                let
                  gateway = cfg.http.gateways.${lib.removePrefix "http-" route};
                in
                {
                  inherit (gateway) service verifyID;
                  localPort = 443;
                }
              );
            })
          ];
        }
      )
    );
  };

  config = mkIf cfg.enable {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: w: [
        {
          assertion = w.runtime == "systemd" && w.isolation.privateNetwork;
          message = "realm.workloads.${name}.http: HTTP adapters require a systemd workload with a private network.";
        }
        {
          assertion = lib.all (domain: builtins.length (gatewayNames [ domain ]) == 1) w.http.internal;
          message = "realm.workloads.${name}.http: each internal name must belong to exactly one HTTPS gateway.";
        }
        {
          assertion =
            w.http.internal == [ ]
            || builtins.length (lib.filter (e: e.localPort == 443) (builtins.attrValues w.egress)) == 1;
          message = "realm.workloads.${name}.http: port 443 must belong only to the generated HTTPS adapter.";
        }
        {
          assertion = builtins.length (gatewayNames w.http.internal) <= 1;
          message = "realm.workloads.${name}.http: one workload can use only one internal HTTPS gateway on port 443.";
        }
      ]) clients
    );

    systemd.services = lib.mapAttrs' (
      _: w:
      let
        noProxy = lib.concatStringsSep "," (
          lib.unique (
            [
              "localhost"
              "127.0.0.1"
              "::1"
            ]
            ++ builtins.attrNames w.isolation.hosts
          )
        );
      in
      lib.nameValuePair (lib.removeSuffix ".service" w.unit) {
        environment = {
          NO_PROXY = noProxy;
          no_proxy = noProxy;
        }
        // lib.optionalAttrs w.http.internet {
          HTTP_PROXY = "http://127.0.0.1:13128";
          HTTPS_PROXY = "http://127.0.0.1:13128";
          http_proxy = "http://127.0.0.1:13128";
          https_proxy = "http://127.0.0.1:13128";
        };
      }
    ) clients;
  };
}
