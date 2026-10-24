{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.realm;
  gatewayNames =
    domains:
    builtins.attrNames (
      lib.filterAttrs (
        _: gateway: lib.any (domain: builtins.elem domain gateway.hosts) domains
      ) cfg.http.gateways
    );
  hosts = w: lib.unique (w.http.internal ++ w.http.gateway.resolveHosts);
  gateways =
    w: if w.http.gateway.ref != null then [ w.http.gateway.ref ] else gatewayNames w.http.internal;
  clients = lib.filterAttrs (
    _: w: w.enable && (w.http.internet || hosts w != [ ] || w.http.gateway.ref != null)
  ) cfg.workloads;
in
{
  options.realm.http.gateways = mkOption {
    default = { };
    description = "HTTPS gateway routing and receiver admission policy.";
    type = types.attrsOf (
      types.submodule {
        options = {
          hosts = mkOption { type = types.listOf types.str; };
          service = mkOption { type = types.str; };
          verifyID = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          admission = mkOption {
            type = types.enum [
              "explicit"
              "declared-clients"
            ];
            default = "explicit";
            description = "Whether the receiver admits explicit identities or declared gateway clients.";
          };
          allowedIDs = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
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
        in
        {
          options.http = {
            internet = lib.mkEnableOption "HTTP Internet access through the Realm proxy";
            gateway = {
              ref = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              resolveHosts = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Local DNS aliases for the selected gateway, without host-level authorization.";
              };
            };
            internal = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Legacy gateway selection by hostname. Use gateway.ref and gateway.resolveHosts for new declarations.";
            };
          };
          config = lib.mkMerge [
            (mkIf w.http.internet {
              egress.internet = {
                service = "internet-proxy";
                localPort = 13128;
              };
            })
            (mkIf (gateways w != [ ]) {
              isolation.hosts = lib.genAttrs (hosts w) (_: "127.0.0.1");
              egress = lib.genAttrs (map (name: "http-${name}") (gateways w)) (
                route:
                let
                  gateway = cfg.http.gateways.${lib.removePrefix "http-" route} or null;
                in
                {
                  service = if gateway == null then "unknown-gateway" else gateway.service;
                  verifyID = lib.mkDefault (if gateway == null then null else gateway.verifyID);
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
          assertion =
            lib.all (domain: builtins.length (gatewayNames [ domain ]) == 1) (hosts w)
            && lib.all (gateway: cfg.http.gateways ? ${gateway}) (gateways w);
          message = "realm.workloads.${name}.http: each name and gateway reference must resolve to one declared gateway.";
        }
        {
          assertion =
            w.http.gateway.ref == null
            || lib.all (domain: builtins.elem domain (cfg.http.gateways.${w.http.gateway.ref}.hosts or [ ])) (
              hosts w
            );
          message = "realm.workloads.${name}.http: resolveHosts must belong to the selected gateway.";
        }
        {
          assertion = hosts w == [ ] || gateways w != [ ];
          message = "realm.workloads.${name}.http: resolveHosts requires a gateway reference.";
        }
        {
          assertion =
            gateways w == [ ]
            || builtins.length (lib.filter (e: e.localPort == 443) (builtins.attrValues w.egress)) == 1;
          message = "realm.workloads.${name}.http: port 443 must belong only to the generated HTTPS adapter.";
        }
        {
          assertion = builtins.length (gateways w) <= 1;
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
