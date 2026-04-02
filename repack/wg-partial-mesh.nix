{
  reIf,
  config,
  lib,
  pkgs,
  inputs',
  ...
}:

let
  inherit (config.networking) hostName;
  thisNode = lib.data.node.${hostName};
  # determine the address family based on the string content
  getFamily = ip: if lib.strings.hasInfix ":" ip then "ip6" else "ip4";
in
reIf {
  # strongswan provides the vici socket required by ranet

  networking = {
    firewall = {
      allowedUDPPorts = [
        39388
      ];
    };
  };
  vaultix.secrets."wg-${hostName}" = {
    owner = "systemd-network";
  };

}
