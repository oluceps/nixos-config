{ lib, config, pkgs, ... }:
let
  cfg = config.services.metrics;
in
{
  options.services.metrics = {
    enable = lib.mkEnableOption "export server metrics";
  };
  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "arp" ];
    };
    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      configFile = (pkgs.formats.yaml { }).generate "config.yml" {
        modules = {
          http_2xx = {
            prober = "http";
          };
        };
      };
    };

    services.caddy.settings.apps.http.servers.srv0.routes = [
      {
        match = [{
          host = [ config.networking.fqdn ];
          path = [ "/metrics" ];
        }];
        handle = [
          {
            handler = "authentication";
            providers.http_basic.accounts = [{
              username = "prometheus";
              password = "$2b$05$EGDkhDEoadOvUkJujmyer.944J2Dh4U73TUtb11Z1bVZwd2rjNECO";
            }];
          }
          {
            handler = "reverse_proxy";
            upstreams = with config.services.prometheus.exporters.node;[{
              dial = "${listenAddress}:${toString port}";
            }];
          }
        ];
      }
      {
        match = [{
          host = [ config.networking.fqdn ];
          path = [ "/probe" ];
        }];
        handle = [
          {
            handler = "authentication";
            providers.http_basic.accounts = [{
              username = "prometheus";
              password = "$2b$05$EGDkhDEoadOvUkJujmyer.944J2Dh4U73TUtb11Z1bVZwd2rjNECO";
            }];
          }
          {
            handler = "reverse_proxy";
            upstreams = with config.services.prometheus.exporters.blackbox;[{
              dial = "${listenAddress}:${toString port}";
            }];
          }
        ];
      }
    ];
  };
}
