{
  cloud.caddy.enable = true;
  cloud.caddy.settings = {
    apps = {
      http = {
        servers = {
          srv0 = {
            listen = [ ":443" ];
            routes = [{
              handle = [{
                handler = "subroute";
                routes = [{
                  handle = [{
                    handler = "reverse_proxy";
                    upstreams = [{
                      dial = "10.0.1.2:6167";
                    }];
                  }];
                  match = [{
                    path = [ "/_matrix/*" ];
                  }];
                }];
              }];
              match = [{
                host = [ "matrix.nyaw.xyz" ];
              }];
              terminal = true;
            }
              {
                handle = [{
                  handler = "subroute";
                  routes = [{
                    handle = [{
                      handler = "reverse_proxy";
                      upstreams = [{
                        dial = "10.0.1.2:8003";
                      }];
                    }];
                  }];
                }];
                match = [{
                  host = [ "vault.nyaw.xyz" ];
                }];
                terminal = true;
              }
              {
                handle = [{
                  handler = "subroute";
                  routes = [{
                    handle = [{
                      handler = "reverse_proxy";
                      upstreams = [{
                        dial = "10.0.1.2:10002";
                      }];
                    }];
                  }];
                }];
                match = [{
                  host = [ "ctos.magicb.uk" ];
                }];
                terminal = true;
              }
              {
                handle = [{
                  handler = "subroute";
                  routes = [{
                    handle = [{
                      auth_credentials = [ "user" "pass" ];
                      handler = "forward_proxy";
                      hide_ip = true;
                      hide_via = true;
                      probe_resistance = { };
                    }
                      {
                        handler = "reverse_proxy";
                        upstreams = [{
                          dial = "127.0.0.1:3999";
                        }];
                      }];
                  }];
                }];
                match = [{
                  host = [ "pb.nyaw.xyz" ];
                }];
                terminal = true;
              }
              {
                handle = [{
                  handler = "subroute";
                  routes = [{
                    handle = [{
                      handler = "file_server";
                      hide = [ "/home/riro/c" ];
                      root = "/var/www/public";
                    }];
                  }];
                }];
                match = [{
                  host = [ "magicb.uk" ];
                }];
                terminal = true;
              }
              {
                handle = [{
                  handler = "subroute";
                  routes = [{
                    handle = [{
                      handler = "headers";
                      response = {
                        set = {
                          Content-Type = [ "application/json" ];
                        };
                      };
                    }
                      {
                        handler = "headers";
                        response = {
                          set = {
                            Access-Control-Allow-Origin = [ "*" ];
                          };
                        };
                      }];
                    match = [{
                      path = [ "/.well-known/matrix/*" ];
                    }];
                  }
                    {
                      handle = [{
                        handler = "static_response";
                        headers = {
                          Location = [ "https://matrix.to/#/@sec:nyaw.xyz" ];
                        };
                        status_code = 302;
                      }];
                      match = [{
                        path = [ "/matrix" ];
                      }];
                    }
                    {
                      handle = [{
                        body = "{
                          \"m.server\": \"matrix.nyaw.xyz:443\"}";
                        handler = "static_response";
                      }];
                      match = [{
                        path = [ "/.well-known/matrix/server" ];
                      }];
                    }
                    {
                      handle = [{
                        body = "{
                          \"m.homeserver\": {
                          \"base_url\": \"https://matrix.nyaw.xyz\"},\"org.matrix.msc3575.proxy\": {
                          \"url\": \"https://matrix.nyaw.xyz\"}}";
                        handler = "static_response";
                      }];
                      match = [{
                        path = [ "/.well-known/matrix/client" ];
                      }];
                    }
                    {
                      handle = [{
                        handler = "reverse_proxy";
                        upstreams = [{
                          dial = "10.0.1.2:3000";
                        }];
                      }];
                    }];
                }];
                match = [{
                  host = [ "nyaw.xyz" ];
                }];
                terminal = true;
              }];
            tls_connection_policies = [{
              certificate_selection = {
                any_tag = [ "cert0" ];
              };
              match = {
                sni = [ "pb.nyaw.xyz" ];
              };
            }
              {
                certificate_selection = {
                  any_tag = [ "cert0" ];
                };
                match = {
                  sni = [ "nyaw.xyz" ];
                };
              }
              { }];
          };
        };
      };
      tls = {
        automation = {
          policies = [{
            subjects = [ "matrix.nyaw.xyz" "vault.nyaw.xyz" "pb.nyaw.xyz" "nyaw.xyz" ];
          }
            {
              issuers = [{
                email = "mn1.674927211@gmail.com";
                module = "acme";
              }
                {
                  email = "mn1.674927211@gmail.com";
                  module = "zerossl";
                }];
              subjects = [ "ctos.magicb.uk" "magicb.uk" ];
            }];
        };
        certificates = {
          load_files = [{
            certificate = "/run/agenix/nyaw.cert";
            key = "/run/agenix/nyaw.key";
            tags = [ "cert0" ];
          }];
        };
      };
    };
  };
}
