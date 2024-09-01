{
  pkgs,
  lib,
  config,
  ...
}:
{

  systemd.services.caddy.serviceConfig.LoadCredential = (map (lib.genCredPath config)) [
    "nyaw.cert"
    "nyaw.key"
  ];

  repack.caddy = {
    enable = true;
    settings = {
      apps = {
        http = {
          servers = {
            srv0 = {
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
                              upstreams = [ { dial = "10.0.1.2:6167"; } ];
                            }
                          ];
                          match = [ { path = [ "/_matrix/*" ]; } ];
                        }
                        {
                          handle = [
                            {
                              handler = "headers";
                              response.set = {
                                X-Frame-Options = [ "SAMEORIGIN" ];
                                X-Content-Type-Options = [ "nosniff" ];
                                X-XSS-Protection = [ "1; mode=block" ];
                                Content-Security-Policy = [ "frame-ancestors 'self'" ];
                              };

                            }
                            (
                              let
                                conf = {
                                  default_server_config = {
                                    "m.homeserver" = {
                                      base_url = "https://matrix.nyaw.xyz";
                                      server_name = "nyaw.xyz";
                                    };
                                  };
                                  show_labs_settings = true;
                                };
                              in
                              {
                                handler = "file_server";
                                root = "${pkgs.element-web.override { inherit conf; }}";
                              }
                            )
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "matrix.nyaw.xyz" ]; } ];
                }
                {
                  handle = [
                    {
                      handler = "subroute";
                      routes = [
                        {
                          handle = [
                            {
                              handler = "reverse_proxy";
                              transport = {
                                protocol = "http";
                                tls = {
                                  server_name = "s3.nyaw.xyz";
                                };
                              };
                              upstreams = [ { dial = "10.0.1.2:443"; } ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "s3.nyaw.xyz" ]; } ];
                }
                {
                  handle = [
                    {
                      handler = "subroute";
                      routes = [
                        {
                          handle = [
                            {
                              handler = "reverse_proxy";
                              transport = {
                                protocol = "http";
                                tls = {
                                  server_name = "cache.nyaw.xyz";
                                };
                              };
                              upstreams = [ { dial = "10.0.1.2:443"; } ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "cache.nyaw.xyz" ]; } ];
                }
                {
                  handle = [
                    {
                      handler = "subroute";
                      routes = [
                        {
                          handle = [
                            {
                              handler = "reverse_proxy";
                              upstreams = [ { dial = "10.0.1.2:8888"; } ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "api.atuin.nyaw.xyz" ]; } ];
                }
                {
                  handle = [
                    {
                      handler = "subroute";
                      routes = [
                        {
                          handle = [
                            {
                              body = builtins.toJSON { "m.server" = "matrix.nyaw.xyz:443"; };
                              status_code = 200;
                              headers = {
                                Access-Control-Allow-Origin = [ "*" ];
                                Content-Type = [ "application/json" ];
                              };
                              handler = "static_response";
                            }
                          ];
                          match = [ { path = [ "/.well-known/matrix/server" ]; } ];
                        }
                        {
                          handle = [
                            {
                              body = builtins.toJSON {
                                "m.homeserver" = {
                                  base_url = "https://matrix.nyaw.xyz";
                                };
                                "org.matrix.msc3575.proxy" = {
                                  url = "https://syncv3.nyaw.xyz";
                                };
                              };
                              handler = "static_response";
                            }
                          ];
                          match = [ { path = [ "/.well-known/matrix/client" ]; } ];
                        }
                        {
                          match = [ { path = [ "/.well-known/webfinger" ]; } ];
                          handle = [
                            {
                              handler = "static_response";
                              status_code = "302";
                              headers = {
                                Access-Control-Allow-Origin = [ "*" ];
                                Location = [ "https://nyaw.xyz/{http.request.uri}" ];
                              };
                            }
                          ];
                        }
                        {
                          handle = [
                            {
                              handler = "reverse_proxy";
                              upstreams = [ { dial = "10.0.1.2:3000"; } ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "nyaw.xyz" ]; } ];
                }

                {
                  handle = [
                    {
                      handler = "subroute";
                      routes = [
                        {
                          handle = [
                            {
                              handler = "reverse_proxy";
                              upstreams = [ { dial = "10.0.1.2:8003"; } ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "vault.nyaw.xyz" ]; } ];
                }
                {
                  handle = [
                    {
                      handler = "rate_limit";
                      rate_limits = {
                        static = {
                          match = [ { method = [ "GET" ]; } ];
                          key = "static";
                          window = "1m";
                          max_events = 10;
                        };
                        dynamic = {
                          key = "{http.request.remote.host}";
                          window = "5s";
                          max_events = 2;
                        };
                      };
                      distributed = { };
                      log_key = true;
                    }
                    {
                      handler = "reverse_proxy";
                      upstreams = [ { dial = "127.0.0.1:3999"; } ];
                    }
                  ];
                  match = [ { host = [ "pb.nyaw.xyz" ]; } ];
                }

                {
                  handle = [
                    {
                      handler = "subroute";
                      routes = [
                        {
                          handle = [
                            {
                              handler = "static_response";
                              headers = {
                                Location = [ "https://{http.request.host}{http.request.uri}" ];
                              };
                              status_code = 302;
                            }
                          ];
                          match = [
                            {
                              method = [ "GET" ];
                              path_regexp = {
                                pattern = "^/([-_a-z0-9]{0,64}$|docs/|static/)";
                              };
                              protocol = "http";
                            }
                          ];
                        }
                        {
                          handle = [
                            {
                              handler = "reverse_proxy";
                              upstreams = [ { dial = "127.0.0.1:2586"; } ];
                            }
                          ];
                        }
                      ];
                    }
                  ];
                  match = [ { host = [ "ntfy.nyaw.xyz" ]; } ];
                }
              ];
            };
          };
        };
      };
    };
  };
}
