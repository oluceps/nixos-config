{
  pkgs,
  config,
  reIf,
  lib,
  ...
}:
reIf {

  networking.firewall.allowedUDPPorts = [ 1234 ];
  services.yggdrasil = {
    enable = true;
    openMulticastPort = true;
    settings = {
      Listen = [ "quic://[::]:1234" ];
      Peers =
        let
          thisNode = lib.data.node.${config.networking.hostName};
          able2Connect =
            peerNode:
            (!peerNode.nat)
            || (thisNode.nat && thisNode ? region && peerNode ? region && thisNode.region == peerNode.region);
        in
        (lib.mapAttrsToList (_: v: "quic://" + (lib.elemAt v.addrs 0) + ":1234") (
          lib.filterAttrs (_: v: able2Connect v) lib.data.node
        ));
    };
    package = pkgs.yggdrasil.overrideAttrs (old: {
      version = old.version + "-patch";
      src = pkgs.fetchFromGitHub {
        owner = "yggdrasil-network";
        repo = "yggdrasil-go";
        rev = "dc521be6ac50f9df82e82451c25b72da9486432a";
        hash = "sha256-lKmI8wdmdnQnuityFJ5ZkfcksqvMiuvEvAgrEhWy5bE=";
      };
      vendorHash = "sha256-z09K/ZDw9mM7lfqeyZzi0WRSedzgKED0Sywf1kJXlDk=";
    });
  };
}
