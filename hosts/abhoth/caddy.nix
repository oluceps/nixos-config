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
                              upstreams = [ { dial = "10.0.3.2:6167"; } ];
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
                  match = [ { host = [ "syncv3.nyaw.xyz" ]; } ];
                  handle = [
                    {
                      handler = "reverse_proxy";
                      upstreams = [ { dial = "unix/${config.services.matrix-sliding-sync.settings.SYNCV3_BINDADDR}"; } ];
                    }
                  ];
                }
              ];
            };
          };
        };
      };
    };
  };
}
