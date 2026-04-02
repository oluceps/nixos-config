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
  ifAble2Connect =
    peerNode: prod:
    lib.optionalAttrs (
      !(
        thisNode.nat
        && peerNode.nat
        && thisNode ? region
        && peerNode ? region
        && thisNode.region != peerNode.region
      )
    ) prod;

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

  systemd.network = {
    networks."10-wireguard-hts" = {
      matchConfig.Name = "hts-0";
      address = [ "fdcc::${toString (thisNode.id + 1)}/64" ];
      networkConfig = {
        IPMasquerade = "ipv6";
        IPv6Forwarding = true;
      };
      networkConfig.DHCP = false;
      linkConfig.RequiredForOnline = false;
    };

    netdevs."10-hts" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "hts-0";
        MTUBytes = 1384;
      };
      wireguardConfig = {
        PrivateKeyFile = config.vaultix.secrets."wg-${hostName}".path;
        ListenPort = 39388;
      };
      wireguardPeers = lib.flatten (
        lib.mapAttrsToList (
          name: peerNode:
          let
            # Pick IPv6 address first, then IPv4
            v6Addr = lib.findFirst (addr: getFamily addr == "ip6") null peerNode.addrs;
            v4Addr = lib.findFirst (addr: getFamily addr == "ip4") null peerNode.addrs;
            endpointAddr = if v6Addr != null then "[${v6Addr}]" else v4Addr;
          in
          if name == hostName || endpointAddr == null then
            [ ]
          else
            let
              peerConfig = ifAble2Connect peerNode {
                PublicKey = peerNode.wg_key;
                AllowedIPs = [
                  "fdcc::${toString (peerNode.id + 1)}"
                ];
                PresharedKeyFile = config.vaultix.secrets.psk.path;
                Endpoint = "${endpointAddr}:39388";
                PersistentKeepalive = 15;
              };
            in
            if peerConfig == { } then [ ] else [ peerConfig ]
        ) lib.data.node
      );
    };
  };

}
