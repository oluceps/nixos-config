{
  flake.modules.nixos.grafana =
    { config, ... }:
    {
      services.grafana = {
        enable = true;
        settings = {
          database = {
            type = "postgres";
            host = "/run/postgresql";
            name = "grafana";
            user = "grafana";
            ssl_mode = "disable";
          };
          server = {
            http_addr = "127.0.0.1";
            http_port = 3002;
            domain = "gf.nyaw.xyz";
            root_url = "https://gf.nyaw.xyz/";
            serve_from_sub_path = false;
          };
          auth = {
            oauth_allow_insecure_email_lookup = true;
          };
          security.secret_key = "$__file{/run/credentials/grafana.service/grafana-secretkey}";
          feature_toggles.dashboardNewLayouts = true;
        };
      };
      realm.workloads.grafana = {
        isolation.runtimePaths = [ "/run/grafana" ];
        isolation.allowUnixSockets = [ "/run/postgresql" ];
        ingress.http = {
          port = 13002;
          target = "127.0.0.1:3002";
          privateLoopback = true;
          service = "grafana";
          allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
        };
        egress = {
          loki = {
            service = "loki";
            verifyID = "spiffe://nyaw.xyz/service/loki";
            localPort = 13030;
          };
          victoriametrics = {
            service = "victoriametrics-${config.networking.hostName}";
            verifyID = "spiffe://nyaw.xyz/service/observability-${config.networking.hostName}";
            localPort = 13090;
          };
          internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/internet";
            localPort = 13128;
          };
        };
      };
      services.grafana.provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:13030";
          }
          {
            name = "VictoriaMetrics";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:13090";
            jsonData = {
              httpMethod = "POST";
              prometheusType = "VictoriaMetrics";
            };
          }
        ];
      };
      systemd.services.grafana = {
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        environment = {
          HTTP_PROXY = "http://127.0.0.1:13128";
          HTTPS_PROXY = "http://127.0.0.1:13128";
          NO_PROXY = "localhost,127.0.0.1,::1";
        };
        serviceConfig.LoadCredential = [
          "grafana-secretkey:${config.vaultix.secrets.grafana-secretkey.path}"
        ];
        # The legacy secret URL selects host TCP and overrides the peer socket settings.
        serviceConfig.UnsetEnvironment = [ "GF_DATABASE_URL" ];
      };
      vaultix.secrets = {
        grafana = {
          owner = "grafana";
          mode = "400";
        };
        grafana-secretkey = {
          owner = "grafana";
          mode = "400";
        };
      };
      systemd.services.grafana.serviceConfig = {
        EnvironmentFile = config.vaultix.secrets.grafana.path;
      };
    };
}
