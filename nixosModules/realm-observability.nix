{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.realm.observability;
  endpoints = lib.filterAttrs (_: e: e.enable) cfg.endpoints;
  publicPath = name: e: "/${name}/${if e.kind == "probe" then "probe" else "metrics"}";
  sds = name: {
    inherit name;
    sds_config = {
      resource_api_version = "V3";
      api_config_source = {
        api_type = "GRPC";
        transport_api_version = "V3";
        grpc_services = [ { envoy_grpc.cluster_name = "observe_spire"; } ];
      };
    };
  };
  luaRules = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: e:
      let
        modules = lib.unique (map (p: p.module) e.probes);
        probes = lib.concatMapStringsSep "," (
          module:
          "[${builtins.toJSON module}] = {"
          + lib.concatMapStringsSep "," (p: "[${builtins.toJSON p.target}] = true") (
            builtins.filter (p: p.module == module) e.probes
          )
          + "}"
        ) modules;
      in
      "[${builtins.toJSON (publicPath name e)}] = ${
        if e.kind == "metrics" then "true" else "{${probes}}"
      },"
    ) endpoints
  );
  httpFilter = {
    name = "envoy.filters.http.lua";
    typed_config = {
      "@type" = "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua";
      default_source_code.inline_string =
        "local allowed_paths = {\n${luaRules}\n}\n" + builtins.readFile ./realm/metrics-filter.lua;
    };
  };
  router = {
    name = "envoy.filters.http.router";
    typed_config."@type" = "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router";
  };
  businessRoutes = e: [
    {
      match.path = "/metrics";
      direct_response.status = 403;
    }
    {
      match.prefix = "/metrics/";
      direct_response.status = 403;
    }
    {
      match.path = e.path;
      direct_response.status = 403;
    }
    {
      match.prefix = e.path + "/";
      direct_response.status = 403;
    }
    {
      match.prefix = "/debug";
      direct_response.status = 403;
    }
  ];
  downstreamTls = allowedIDs: {
    name = "envoy.transport_sockets.tls";
    typed_config = {
      "@type" = "type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext";
      require_client_certificate = true;
      common_tls_context = {
        tls_params.tls_minimum_protocol_version = "TLSv1_3";
        tls_certificate_sds_secret_configs = [ (sds config.realm.workloads.observability.spiffeID) ];
        combined_validation_context = {
          default_validation_context.match_typed_subject_alt_names = map (id: {
            san_type = "URI";
            matcher.exact = id;
          }) allowedIDs;
          validation_context_sds_secret_config = sds "spiffe://${config.realm.trustDomain}";
        };
      };
    };
  };
  protectedPorts = lib.unique (
    map (e: e.port) (
      builtins.attrValues (
        lib.filterAttrs (
          _: e:
          e.port != null
          && builtins.elem e.address [
            "127.0.0.1"
            "::1"
          ]
          && e.publicProxyPort != e.port
        ) endpoints
      )
    )
  );
  hcm = routes: filters: {
    name = "envoy.filters.network.http_connection_manager";
    typed_config = {
      "@type" =
        "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager";
      stat_prefix = "observability";
      normalize_path = true;
      merge_slashes = true;
      path_with_escaped_slashes_action = "REJECT_REQUEST";
      max_request_headers_kb = 16;
      stream_idle_timeout = "30s";
      route_config = {
        name = "observability";
        virtual_hosts = [
          {
            name = "observability";
            domains = [ "*" ];
            inherit routes;
          }
        ];
      };
      http_filters = filters ++ [ router ];
    };
  };
in
{
  options.realm.observability = {
    enable = lib.mkEnableOption "SPIFFE authenticated, path-restricted observation endpoints";
    port = lib.mkOption {
      type = lib.types.port;
      default = 19490;
    };
    allowedIDs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "spiffe://${config.realm.trustDomain}/service/vmagent" ];
    };
    endpoints = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              address = lib.mkOption {
                type = lib.types.str;
                default = "127.0.0.1";
              };
              port = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
              };
              socket = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
              path = lib.mkOption {
                type = lib.types.str;
                default = "/metrics";
              };
              kind = lib.mkOption {
                type = lib.types.enum [
                  "metrics"
                  "probe"
                ];
                default = "metrics";
              };
              probes = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      module = lib.mkOption { type = lib.types.str; };
                      target = lib.mkOption { type = lib.types.str; };
                    };
                  }
                );
                default = [ ];
              };
              publicProxyPort = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
                description = "Preserve a shared business HTTP port while denying metrics and debug paths there.";
              };
              businessProxyPort = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
                description = "Additional mTLS business API listener with an explicit caller allowlist, excluding metrics and debug paths.";
              };
              businessAllowedIDs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "SPIFFE IDs permitted to use businessProxyPort.";
              };
              businessService = lib.mkOption {
                type = lib.types.str;
                default = "${name}-${config.networking.hostName}";
                description = "DNS service name that advertises businessProxyPort for SRV discovery.";
              };
            };
          }
        )
      );
    };
  };
  config = lib.mkIf cfg.enable {
    networking.nftables = {
      enable = true;
      tables.realm-observability = lib.mkIf (protectedPorts != [ ]) {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority -5; policy accept;
            iifname != "lo" tcp dport { ${lib.concatMapStringsSep ", " toString protectedPorts} } drop
          }
        '';
      };
    };
    assertions = lib.mapAttrsToList (name: e: {
      assertion =
        builtins.match "[a-z][a-z0-9-]*" name != null
        && ((e.port == null) != (e.socket == null))
        && (e.kind != "probe" || e.probes != [ ])
        && (e.publicProxyPort == null || e.kind == "metrics")
        && (
          e.businessProxyPort == null
          || (
            e.kind == "metrics"
            && e.businessAllowedIDs != [ ]
            && e.businessProxyPort != e.port
            && e.businessProxyPort != e.publicProxyPort
          )
        );
      message = "realm.observability.endpoints.${name}: declare one backend and an explicit probe allowlist.";
    }) endpoints;
    services.envoy = {
      enable = true;
      settings = {
        node = {
          id = config.networking.hostName;
          cluster = lib.mkDefault "realm-observability";
        };
        static_resources = {
          listeners = [
            {
              name = "observability_mtls";
              address.socket_address = {
                address = config.realm.address;
                port_value = cfg.port;
              };
              per_connection_buffer_limit_bytes = 65536;
              filter_chains = [
                {
                  transport_socket = downstreamTls cfg.allowedIDs;
                  filters = [
                    (hcm (lib.mapAttrsToList (name: e: {
                      match.path = publicPath name e;
                      route = {
                        cluster = "observe_${name}";
                        prefix_rewrite = e.path;
                        timeout = "20s";
                        host_rewrite_literal = "localhost";
                      };
                    }) endpoints) [ httpFilter ])
                  ];
                }
              ];
            }
          ]
          ++ lib.mapAttrsToList (name: e: {
            name = "observe_forward_${name}";
            address.socket_address = {
              address = config.realm.address;
              port_value = e.businessProxyPort;
            };
            per_connection_buffer_limit_bytes = 65536;
            filter_chains = [
              {
                transport_socket = downstreamTls e.businessAllowedIDs;
                filters = [
                  (hcm (
                    businessRoutes e
                    ++ [
                      {
                        match.prefix = "/";
                        route = {
                          cluster = "observe_${name}";
                          timeout = "0s";
                        };
                      }
                    ]
                  ) [ ])
                ];
              }
            ];
          }) (lib.filterAttrs (_: e: e.businessProxyPort != null) endpoints)
          ++ lib.mapAttrsToList (name: e: {
            name = "observe_business_${name}";
            address.socket_address = {
              address = config.realm.address;
              port_value = e.publicProxyPort;
            };
            filter_chains = [
              {
                filters = [
                  (hcm (
                    businessRoutes e
                    ++ [
                      {
                        match.prefix = "/";
                        route = {
                          cluster = "observe_${name}";
                          timeout = "0s";
                        };
                      }
                    ]
                  ) [ ])
                ];
              }
            ];
          }) (lib.filterAttrs (_: e: e.publicProxyPort != null) endpoints);
          clusters = [
            {
              name = "observe_spire";
              type = "STATIC";
              connect_timeout = "1s";
              typed_extension_protocol_options."envoy.extensions.upstreams.http.v3.HttpProtocolOptions" = {
                "@type" = "type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions";
                explicit_http_config.http2_protocol_options = { };
              };
              load_assignment = {
                cluster_name = "observe_spire";
                endpoints = [ { lb_endpoints = [ { endpoint.address.pipe.path = config.realm.spire.socket; } ]; } ];
              };
            }
          ]
          ++ lib.mapAttrsToList (name: e: {
            name = "observe_${name}";
            type = "STATIC";
            connect_timeout = "3s";
            load_assignment = {
              cluster_name = "observe_${name}";
              endpoints = [
                {
                  lb_endpoints = [
                    {
                      endpoint.address =
                        if e.socket != null then
                          { pipe.path = e.socket; }
                        else
                          {
                            socket_address = {
                              inherit (e) address;
                              port_value = e.port;
                            };
                          };
                    }
                  ];
                }
              ];
            };
          }) endpoints;
        };
      };
    };
    systemd.services.envoy.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "envoy";
      Group = "envoy";
      AmbientCapabilities = lib.mkForce [ ];
      CapabilityBoundingSet = lib.mkForce [ ];
      Restart = lib.mkForce "on-failure";
      RestartSec = "3s";
    };
    realm.workloads.observability = {
      unit = "envoy.service";
      user = "envoy";
      group = "envoy";
      spiffeID = "spiffe://${config.realm.trustDomain}/service/observability-${config.networking.hostName}";
      runtime = "external";
      isolation.privateNetwork = false;
      ingress.metrics = {
        native = true;
        port = cfg.port;
        service = "observability-${config.networking.hostName}";
        allowedIDs = cfg.allowedIDs;
      };
    };
    realm.serviceDiscovery.publish = lib.mapAttrs' (
      name: e:
      lib.nameValuePair e.businessService {
        unit = "envoy.service";
        port = e.businessProxyPort;
      }
    ) (lib.filterAttrs (_: e: e.businessProxyPort != null) endpoints);
  };
}
