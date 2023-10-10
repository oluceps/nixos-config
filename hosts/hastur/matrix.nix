{ config
, pkgs
, inputs
, ...
}:

let
  server_name = "nyaw.xyz";
in

{
  services.matrix-conduit = {
    enable = true;

    package = inputs.conduit.packages.${pkgs.system}.default;

    settings.global = {
      inherit server_name;
      database_backend = "rocksdb";
      port = 6167;
    };
  };
  networking.firewall =
    let port = config.services.matrix-conduit.settings.global.port; in {
      allowedTCPPorts = [ port ];
      allowedUDPPorts = [ port ];
    };
}

