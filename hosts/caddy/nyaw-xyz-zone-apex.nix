{
  handle = [
    {
      handler = "subroute";
      routes = [
        {
          handle = [
            {
              handler = "headers";
              response = {
                set = {
                  Access-Control-Allow-Origin = [ "*" ];
                };
              };
            }
          ];
          match = [ { path = [ "/.well-known/matrix/*" ]; } ];
        }
        {
          handle = [
            {
              body = builtins.toJSON { "m.server" = "matrix.nyaw.xyz:443"; };
              handler = "static_response";
              status_code = 200;
              headers = {
                Access-Control-Allow-Origin = [ "*" ];
                Content-Type = [ "application/json" ];
              };
            }
          ];
          match = [ { path = [ "/.well-known/matrix/server" ]; } ];
        }
        {
          handle = [
            {
              handler = "reverse_proxy";
              upstreams = [ { dial = "[fdcc::3]:8196"; } ];
            }
          ];
          match = [ { path = [ "/.well-known/matrix/client" ]; } ];
        }
        {
          handle = [
            {
              handler = "reverse_proxy";
              transport = {
                protocol = "http";
                tls = {
                  server_name = "nyaw.xyz";
                };
              };
              upstreams = [ { dial = "[fdcc::3]:443"; } ];
            }
          ];
        }
      ];
    }
  ];
  match = [ { host = [ "nyaw.xyz" ]; } ];
  terminal = true;
}
