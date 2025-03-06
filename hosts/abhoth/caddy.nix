{
  pkgs,
  lib,
  config,
  ...
}:
{

  repack.reuse-cert.enable = false;
  # systemd.services.caddy.serviceConfig.LoadCredential = (map (lib.genCredPath config)) [
  #   "nyaw.cert"
  #   "nyaw.key"
  # ];
  repack.caddy = {
    enable = true;
    settings.apps.http.servers = {
      srv0 = {
        routes = [
          {
            handle = [
              {
                handler = "subroute";
                routes = [
                  (import ../caddy-matrix.nix {
                    inherit pkgs;
                    matrix-upstream = "[fdcc::3]:6167";
                  })
                ];
              }
            ];
            match = [ { host = [ "*.nyaw.xyz" ]; } ];
          }
        ];
      };
    };
  };
}
