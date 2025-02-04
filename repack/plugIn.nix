{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.repack.plugIn;

  inherit (builtins) readFile fromTOML attrValues;
  inherit (lib) concatMapAttrs optionalAttrs singleton;
  inherit (fromTOML (readFile ../hosts/sum.toml)) node;
  inherit (config.networking) hostName;
  allConn = (lib.conn { }).${hostName};

  allowedUDPPorts = attrValues allConn;

  genPeerCfg =
    peerName: port:
    let
      peerNode = node.${peerName};
      thisNode = node.${hostName};
    in
    {
      netdevs."wg-${peerName}" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-${peerName}";
          MTUBytes = "1300";
        };
        wireguardConfig =
          {
            PrivateKeyFile = config.vaultix.secrets."wg-${hostName}".path;
            RouteTable = false;
          }
          // (optionalAttrs thisNode.censor {
            ListenPort = port;
          });
        wireguardPeers = singleton (
          {
            PublicKey = peerNode.pub_key;
            AllowedIPs = [
              "::/0"
              "0.0.0.0/0"
            ];
            Endpoint =
              let
                port = toString allConn.${peerName};
                addr = if (thisNode.censor || peerNode.censor) then "127.0.0.1" else peerNode.addr;
              in
              (addr + ":" + port);
            RouteTable = false;
          }
          // optionalAttrs thisNode.censor {
            PersistentKeepalive = 15;
          }
        );
      };

      networks."10-wg-${peerName}" = {
        matchConfig.Name = "wg-${peerName}";
        addresses = [
          {
            Address = thisNode.unique_addr;
            Peer = peerNode.unique_addr;
          }
          {
            Address = thisNode.link_local_addr;
            Peer = peerNode.link_local_addr;
            Scope = "link";
          }
        ];
        networkConfig = {
          DHCP = false;
        };
      };
    };

in
{
  config = lib.mkIf cfg.enable {

    networking.firewall = { inherit allowedUDPPorts; };

    systemd.network = concatMapAttrs genPeerCfg allConn;
  };
}
