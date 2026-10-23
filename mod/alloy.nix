{
  flake.modules.nixos.alloy-realm =
    { config, lib, ... }:
    {
      services.alloy.enable = lib.mkIf (config.realm.internet.enable or false) (lib.mkDefault true);
      realm.workloads.alloy = lib.mkIf config.services.alloy.enable {
        isolation.allowUnixSockets = [
          "-/run/log/journal"
          "-/run/systemd/journal"
        ];
        egress.loki = {
          service = "loki";
          localPort = 13030;
        };
      };
      environment.etc = lib.mkIf (config.realm.internet.enable or false) {
        "alloy/realm-internet.alloy".text = # alloy
          ''
            loki.source.journal "realm_internet" {
                max_age       = "12h0m0s"
                forward_to    = [loki.write.realm_internet.receiver]
                matches       = "_SYSTEMD_UNIT=realm-internet.service"
                labels        = {
                    host = "${config.networking.hostName}",
                    job  = "systemd-journal",
                    unit = "realm-internet.service",
                }
            }
            loki.write "realm_internet" {
              endpoint {
                url = "http://127.0.0.1:13030/loki/api/v1/push"
              }
              external_labels = {}
            }
          '';
      };
    };
  flake.modules.nixos.alloy =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.alloy = {
        enable = true;
      };
      systemd.services.alloy.serviceConfig = {
        ReadOnlyPaths = [ "/var/log/zeek" ];
      };
      environment.etc."alloy/config.alloy".text = # alloy
        ''
          livedebugging {
            enabled = false
          }
          discovery.relabel "journal" {
          	targets = []
          	rule {
          		source_labels = ["__journal__systemd_unit"]
          		target_label  = "unit"
          	}
          }
          loki.source.journal "sshd" {
              max_age       = "12h0m0s"
              relabel_rules = discovery.relabel.journal.rules
              forward_to    = [loki.write.default.receiver]
              matches       = "_SYSTEMD_UNIT=sshd.service"
              labels        = {
                  host = "${config.networking.hostName}",
                  job  = "systemd-journal",
              }
          }
          loki.source.journal "sudo" {
              max_age       = "12h0m0s"
              relabel_rules = discovery.relabel.journal.rules
              forward_to    = [loki.write.default.receiver]
              matches       = "_COMM=sudo"
              labels        = {
                  host = "${config.networking.hostName}",
                  job  = "systemd-journal",
                  comm = "sudo",
              }
          }
          loki.source.journal "kernel" {
              max_age       = "12h0m0s"
              relabel_rules = discovery.relabel.journal.rules
              forward_to    = [loki.write.default.receiver]
              matches       = "_TRANSPORT=kernel"
              labels        = {
                  host = "${config.networking.hostName}",
                  job  = "systemd-journal",
              }
          }
          local.file_match "zeek_logs" {
            path_targets = [
              { "__path__" = "/var/log/zeek/vm1/dns.log" },
              { "__path__" = "/var/log/zeek/vm1/ssl.log" },
              { "__path__" = "/var/log/zeek/eno1/dns.log" },
              { "__path__" = "/var/log/zeek/eno1/ssl.log" },
            ]
            sync_period = "5s"
          }

          loki.source.file "zeek_logs" {
            targets    = local.file_match.zeek_logs.targets
            forward_to = [loki.write.default.receiver]
            tail_from_end = true
          }

          local.file_match "zeek_conns" {
            path_targets = [
              { "__path__" = "/var/log/zeek/vm1/conn.log" },
              { "__path__" = "/var/log/zeek/eno1/conn.log" },
            ]
            sync_period = "5s"
          }

          loki.source.file "zeek_conns" {
            targets    = local.file_match.zeek_conns.targets
            forward_to = [loki.process.conn_geo.receiver]
            tail_from_end = true
          }

          loki.process "conn_geo" {
            stage.json {
              expressions = {
                ts        = "ts",
                dst = "\"id.resp_h\"",
                dpt = "\"id.resp_p\"",
                proto     = "proto",
                ip_proto  = "ip_proto",
              }
            }

            stage.geoip {
              source  = "dst"
              db      = "${
                let
                  sources = import ../_sources/generated.nix {
                    inherit (pkgs)
                      fetchurl
                      fetchgit
                      fetchFromGitHub
                      dockerTools
                      ;
                  };
                in
                sources.GeoLite2-ASN.src
              }"
              db_type = "asn"
            }
            stage.geoip {
              source  = "dst"
              db      = "${
                let
                  sources = import ../_sources/generated.nix {
                    inherit (pkgs)
                      fetchurl
                      fetchgit
                      fetchFromGitHub
                      dockerTools
                      ;
                  };
                in
                sources.GeoLite2-City.src
              }"
              db_type = "city"
            }

            stage.labels {
              values = {
                proto     = "",
              }
            }
            stage.structured_metadata {
                values = {
                  dst      = "",
                  dpt      = "",
                  dst_city = "geoip_city_name",
                  dst_asn  = "geoip_autonomous_system_organization",
                  dst_lat  = "geoip_location_latitude",
                  dst_lon  = "geoip_location_longitude",
                }
            }
            forward_to = [loki.write.default.receiver]
          }

          loki.write "default" {
          	endpoint {
              url = "http://127.0.0.1:13030/loki/api/v1/push"
          	}
          	external_labels = {}
          }
        '';
    };
}
