{ config
, pkgs
, inputs
, ...
}:

let
  server_name = "nyaw.xyz";
in

{
  # Configure Conduit itself
  services.matrix-conduit = {
    enable = true;

    # This causes NixOS to use the flake defined in this repository instead of
    # the build of Conduit built into nixpkgs.
    package = inputs.conduit.packages.${pkgs.system}.default;

    settings.global = {
      inherit server_name;
    };
  };


  # Open firewall ports for HTTP, HTTPS, and Matrix federation
  networking.firewall.allowedTCPPorts = [ 80 443 8448 ];
  networking.firewall.allowedUDPPorts = [ 80 443 8448 ];
}

