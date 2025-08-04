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
      ];
    }

    {
      handler = "headers";
      response.set = {
        X-Frame-Options = [ "SAMEORIGIN" ];
        X-Content-Type-Options = [ "nosniff" ];
        X-XSS-Protection = [ "1; mode=block" ];
        Content-Security-Policy = [ "frame-ancestors 'self'" ];
      };
    }
    {
      handler = "subroute";
      routes = [
        {
          handle = [
            {
              handler = "rewrite";
              uri = "/olm.wasm";
            }
          ];
          match = [ { path = [ "/*/olm.wasm" ]; } ];
        }
        {
          handle = [
            {
              handler = "rewrite";
              uri = "/index.html";
            }
          ];
          match = [
            {
              not = [
                { path = [ "/index.html" ]; }
                { path = [ "/public/*" ]; }
                { path = [ "/assets/*" ]; }
                { path = [ "/config.json" ]; }
                { path = [ "/manifest.json" ]; }
                { path = [ "/pdf.worker.min.js" ]; }
                { path = [ "/olm.wasm" ]; }
              ];
              path = [ "/*" ];
            }
          ];
        }
      ];
    }
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
        root = "${pkgs.cinny.override { inherit conf; }}";
      }
    )
  ];
  match = [ { host = [ "matrix.nyaw.xyz" ]; } ];
  terminal = true;
}
