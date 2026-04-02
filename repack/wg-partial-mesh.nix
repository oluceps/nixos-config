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
  networking = {
    firewall = {
      allowedUDPPorts = [
        39388
      ];
    };
  };

  vaultix.secrets = {
    "wg-${hostName}" = {
      owner = "systemd-network";
    };
    psk = {
      owner = "systemd-network";
    };
  };

  systemd.network = {
    networks."10-wireguard-hts" = {
      matchConfig.Name = "hts-0";
      addresses = [
        "fdcc::${toString (thisNode.id + 1)}/128"
      ];
      routes = [
        {
          Destination = "fdcc::/64";
          Metric = 100;
        }
      ];
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
            potentialEndpoints = lib.filter (addr: !lib.hasPrefix "fdcc:" addr) (peerNode.addrs or [ ]);

            v6Addr = lib.findFirst (addr: getFamily addr == "ip6") null potentialEndpoints;
            v4Addr = lib.findFirst (addr: getFamily addr == "ip4") null potentialEndpoints;
            endpointAddr = if v6Addr != null then "[${v6Addr}]" else v4Addr;
          in
          if name == hostName then
            [ ]
          else
            let
              peerConfig = ifAble2Connect peerNode (
                {
                  PublicKey = peerNode.wg_key;
                  AllowedIPs = [
                    "fdcc::${toString (peerNode.id + 1)}/128"
                  ];
                  PresharedKeyFile = config.vaultix.secrets.psk.path;
                  PersistentKeepalive = 15;
                }
                // lib.optionalAttrs (endpointAddr != null) {
                  Endpoint = "${endpointAddr}:39388";
                }
              );
            in
            if peerConfig == { } then [ ] else [ peerConfig ]
        ) lib.data.node
      );
    };
  };
}
