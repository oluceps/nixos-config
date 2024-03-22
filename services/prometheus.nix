{ config, pkgs, lib, ... }:
let
  targets = map (n: "${n}.nyaw.xyz") [ "nodens" "colour" "hastur" ];
in
{
  enable = true;
  webExternalUrl = "https://${config.networking.fqdn}/prom";
  listenAddress = "0.0.0.0";
  port = 9090;
  retentionTime = "7d";
  globalConfig = {
    scrape_interval = "1m";
    evaluation_interval = "1m";
  };
  scrapeConfigs = [
    {
      job_name = "caddy";
      scheme = "https";
      basic_auth = {
        username = "prometheus";
        password_file = "/run/credentials/prometheus.service/wg";
      };
      metrics_path = "/caddy";
      static_configs = [{ inherit targets; }];
    }
    {
      job_name = "mosdns";
      metrics_path = "/metrics";
      static_configs = [{ targets = [ "localhost:9092" ]; }];
    }
    {
      job_name = "metrics";
      scheme = "https";
      metrics_path = "/metrics";
      basic_auth = {
        username = "prometheus";
        password_file = "/run/credentials/prometheus.service/wg";
      };
      static_configs = [{ inherit targets; }];
    }
    # {
    #   job_name = "http";
    #   scheme = "https";
    #   basic_auth = {
    #     username = "prometheus";
    #     password_file = "/run/credentials/prometheus.service/wg";
    #   };
    #   metrics_path = "/probe";
    #   params = {
    #     module = [ "http_2xx" ];
    #     target = [ "https://nyaw.xyz" ];
    #   };
    #   static_configs = [{ inherit targets; }];
    #   relabel_configs = [{
    #     source_labels = [ "__param_target" ];
    #     target_label = "target";
    #   }];
    # }
  ];
  rules = lib.singleton (builtins.toJSON {
    groups = [{
      name = "metrics";
      rules = [
        {
          alert = "NodeDown";
          expr = ''up == 0'';
        }
        {
          alert = "OOM";
          expr = ''node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1'';
        }
        {
          alert = "DiskFull";
          expr = ''node_filesystem_avail_bytes{mountpoint=~"/persist|/data"} / node_filesystem_size_bytes < 0.1'';
        }
        {
          alert = "UnitFailed";
          expr = ''node_systemd_unit_state{state="failed"} == 1'';
        }
      ];
    }];
  });
  alertmanagers = [{
    static_configs = [{
      targets = [ "127.0.0.1:8009" ];
    }];
  }];

  exporters = {
    node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "arp" ];
    };
    blackbox = {
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
  };
}
