{ pkgs, matrix-upstream, ... }:
{
  handle = [
    {
      handler = "subroute";
      routes = [
        {
          handle = [
            {
              handler = "reverse_proxy";
              upstreams = [ { dial = matrix-upstream; } ];
            }
          ];
          match = [
            {
              path = [ "/_matrix/*" ];
            }
          ];
          terminal = true;
        }

        {
          handle = [
            {
              handler = "rewrite";
              uri = "{http.matchers.file.relative}";
            }
          ];
          match = [
            {
              file = {
                try_files = [
                  "{http.request.uri.path}"
                  "/"
                  "index.html"
                ];
              };
            }
          ];
        }
        {
          handle = [
            (
              let
                conf = {
                  defaultHomeserver = 0;
                  homeserverList = [
                    "nyaw.xyz"
                    "converser.eu"
                    "envs.net"
                    "matrix.org"
                    "monero.social"
                    "mozilla.org"
                    "xmr.se"
                  ];
                };
              in
              {
                handler = "file_server";
                root = pkgs.cinny.override { inherit conf; };
              }
            )
          ];
        }

      ];
    }

  ];
  match = [ { host = [ "matrix.nyaw.xyz" ]; } ];
  terminal = true;
}
