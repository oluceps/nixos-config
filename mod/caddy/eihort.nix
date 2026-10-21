{ self, ... }:
{
  flake.modules.nixos."caddy/eihort" =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        self.modules.nixos.caddy-public
        self.modules.nixos.caddy-public-relay
      ];

      realm.workloads.caddy = {
        egress = {
          pocket-id = {
            service = "pocket-id";
            verifyID = "${config.realm.servicePrefix}pocket-id";
          };
          jellyfin = {
            service = "jellyfin";
            verifyID = "spiffe://nyaw.xyz/service/jellyfin";
          };
          vaultwarden = {
            service = "vaultwarden";
            verifyID = "spiffe://nyaw.xyz/service/vaultwarden";
          };
          forgejo = {
            service = "forgejo";
            verifyID = "spiffe://nyaw.xyz/service/forgejo";
          };
          # telegram-search = {
          #   service = "telegram-search";
          #   verifyID = "spiffe://nyaw.xyz/service/telegram-search";
          # };
          synapse = {
            service = "synapse";
            verifyID = "spiffe://nyaw.xyz/service/synapse";
          };
          calibre = {
            service = "calibre";
            verifyID = "spiffe://nyaw.xyz/service/calibre";
          };
          s3 = {
            service = "seaweedfs-s3";
            verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
          };
          seaweedfs = {
            service = "seaweedfs-master";
            verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
          };
          grafana = {
            service = "grafana";
            verifyID = "spiffe://nyaw.xyz/service/grafana";
          };
          misskey = {
            service = "misskey";
            verifyID = "spiffe://nyaw.xyz/service/misskey";
          };
          meilisearch = {
            service = "meilisearch";
            verifyID = "spiffe://nyaw.xyz/service/meilisearch";
          };
          immich = {
            service = "immich";
            verifyID = "spiffe://nyaw.xyz/service/immich";
          };
          immich-public-proxy = {
            service = "immich-public-proxy";
            verifyID = "spiffe://nyaw.xyz/service/immich-public-proxy";
          };
        };
        ingress.public-edge = {
          port = 19444;
          target = "127.0.0.1:443";
          hostLoopback = true;
          service = "internal-https";
          allowedIDs = config.realm.caddy.allowedIDs.internal-https;
        };
        ingress.https = {
          port = 19443;
          target = "127.0.0.1:443";
          hostLoopback = true;
          service = "s3-https";
          allowedIDs = [
            "spiffe://nyaw.xyz/service/forgejo"
            "spiffe://nyaw.xyz/service/ncps"
            "spiffe://nyaw.xyz/service/misskey"
            "spiffe://nyaw.xyz/service/telegram-search"
            "spiffe://nyaw.xyz/service/synapse"
          ];
        };
      };

      vaultix.secrets."nyaw.key" = {
        mode = "400";
        owner = config.identity.user;
      };
      vaultix.secrets."nyaw.cert" = {
        cleanPlaceholder = true;
        mode = "400";
        owner = config.identity.user;
        insert = {
          "aa778b04d0a03257ce38ecfc17c225fe019a5369d50b2b51a47af2dcc3b446ef" = {
            content = config.fn.pki.intermediate;
          };
        };
      };

      caddy = {
        settings.apps = {
          http.servers.srv0 = {
            routes = [
              {
                handle = [
                  {
                    handler = "subroute";
                    routes = [
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/s3.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "s3.nyaw.xyz" ]; } ];
                      }
                      {
                        match = [
                          {
                            host = [ "alert.nyaw.xyz" ];
                            path = [
                              "/metrics"
                              "/metrics/*"
                              "/debug/*"
                            ];
                          }
                        ];
                        handle = [
                          {
                            handler = "static_response";
                            status_code = 403;
                          }
                        ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "127.0.0.1:9093"; } ];
                          }
                        ];
                        match = [ { host = [ "alert.nyaw.xyz" ]; } ];
                      }
                      # {
                      #   handle = [
                      #     {
                      #       handler = "reverse_proxy";
                      #       headers.request.set.X-Real-Ip = [ "{http.request.remote.host}" ];
                      #       upstreams = [ { dial = "unix//run/realm/caddy/egress/vaultwarden.sock"; } ];
                      #     }
                      #   ];
                      #   match = [ { host = [ "vault.nyaw.xyz" ]; } ];
                      #   terminal = true;
                      # }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [
                              { dial = "unix//run/realm/caddy/egress/forgejo.sock"; }
                            ];
                          }
                        ];
                        match = [ { host = [ "git.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/telegram-search.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "tgs.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "[fdcc::1]:3010"; } ];
                          }
                        ];
                        match = [ { host = [ "heartrate.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "[fdcc::3]:8084"; } ];
                          }
                        ];
                        match = [ { host = [ "seed.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/jellyfin.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "jellyfin.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/seaweedfs.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "seaweedfs.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "[fdcc::3]:5230"; } ];
                          }
                        ];
                        match = [ { host = [ "memos.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/immich-public-proxy.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "photo.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "[fdcc::3]:3031"; } ];
                          }
                        ];
                        match = [ { host = [ "rqbit.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/meilisearch.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "ms.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "127.0.0.1:8090"; } ];
                          }
                        ];
                        match = [ { host = [ "scrutiny.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/pocket-id.sock"; } ];
                            response_buffers = 2097152;
                          }
                        ];
                        match = [ { host = [ "oidc.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/vaultwarden.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "vault.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "[fdcc::3]:5244"; } ];
                          }
                        ];
                        match = [ { host = [ "alist.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            body = "User-agent: *\\nDisallow: /";
                            handler = "static_response";
                          }
                        ];
                        match = [
                          {
                            host = [ "book.nyaw.xyz" ];
                            path = [ "/robots.txt" ];
                          }
                        ];
                      }
                      {
                        handle = [
                          {
                            headers = {
                              request = {
                                set = {
                                  "X-Robots-Tag" = [ "noindex, nofollow" ];
                                  "X-Scheme" = [
                                    "https"
                                  ];
                                };
                              };
                            };
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/calibre.sock"; } ];
                            handler = "reverse_proxy";
                          }
                        ];
                        match = [ { host = [ "book.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      {
                        handle = [
                          {
                            handler = "reverse_proxy";
                            upstreams = [ { dial = "unix//run/realm/caddy/egress/grafana.sock"; } ];
                          }
                        ];
                        match = [ { host = [ "gf.nyaw.xyz" ]; } ];
                        terminal = true;
                      }
                      (import ../../caddy/matrix.nix {
                        inherit pkgs;
                        matrix-upstream = "unix//run/realm/caddy/egress/synapse.sock";
                      })
                    ];
                  }
                ];
                match = [ { host = [ "*.nyaw.xyz" ]; } ];
              }
              {
                handle = [
                  (import ../../caddy/nyaw-xyz-matrix-wellknown.nix)
                  {
                    handler = "reverse_proxy";
                    upstreams = [ { dial = "unix//run/realm/caddy/egress/misskey.sock"; } ];
                    trusted_proxies = [
                      "fdcc::4"
                      "fdcc::5"
                      "fdcc::6"
                    ];
                  }

                ];
                match = [ { host = [ "nyaw.xyz" ]; } ];
              }
            ];

            # tls_connection_policies = [
            #   {
            #     match = {
            #       sni = [
            #         "*.*.nyaw.xyz"
            #         "*.nyaw.xyz"
            #         "nyaw.xyz"
            #       ];
            #     };
            #     protocol_min = "tls1.3";
            #   }
            # ];
            tls_connection_policies = [
              {
                match = {
                  sni = [
                    "*.*.nyaw.xyz"
                    "*.nyaw.xyz"
                    "nyaw.xyz"
                  ];
                };
                certificate_selection = {
                  any_tag = [ "cert0" ];
                };
                protocol_min = "tls1.3";
              }
            ];
          };

          # tls =
          #   let
          #     dns = {
          #       name = "cloudflare";
          #       api_token = "{env.CF_API_TOKEN}";
          #       zone_token = "{env.CF_ZONE_TOKEN}";
          #     };
          #   in
          #   {
          #     inherit dns;
          #     automation.policies = [
          #       {
          #         issuers = [
          #           {
          #             module = "acme";
          #             email = "mn1.674927211@gmail.com";
          #             challenges.dns.provider = dns;
          #             preferred_chains.smallest = true;
          #           }
          #         ];
          #         key_type = "p256";
          #       }
          #     ];
          #     encrypted_client_hello.configs = [
          #       {
          #         public_name = "nyaw.xyz";
          #       }
          #     ];
          #   };
          tls = {
            certificates.load_files = [
              {
                certificate = "/run/credentials/caddy.service/nyaw.cert";
                key = "/run/credentials/caddy.service/nyaw.key";
                tags = [ "cert0" ];
              }
            ];
          };
        };

      };
    };
}
