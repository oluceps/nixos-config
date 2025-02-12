{
  config,
  lib,
  ...
}:

let
  cfg = config.repack.plugIn;

  inherit (builtins)
    readFile
    fromTOML
    attrNames
    attrValues
    ;
  inherit (lib)
    concatMapAttrs
    optionalAttrs
    singleton
    concatMapStrings
    getAddrFromCIDR
    ;
  inherit (fromTOML (readFile ../hosts/sum.toml)) node;
  inherit (config.networking) hostName;
  peerPortsMap = (lib.conn { }).${hostName};
  thisHost = node.${hostName};
  thisId = toString (thisHost.id + 1);
  allowedUDPPorts = attrValues peerPortsMap;
  trustedInterfaces = map (n: "wg-" + n) (attrNames peerPortsMap);

  genPeerNetwork =
    peerName: port:
    let
      peerNode = node.${peerName};
      thisNode = node.${hostName};
    in
    {
      "10-wg-${peerName}" = {
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
  genPeerNetdev =
    peerName: port:
    let
      peerNode = node.${peerName};
      thisNode = node.${hostName};
    in
    {
      "wg-${peerName}" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-${peerName}";
          MTUBytes = "1440";
        };
        wireguardConfig =
          {
            PrivateKeyFile = config.vaultix.secrets."wg-${hostName}".path;
            RouteTable = false;
          }
          // (optionalAttrs ((thisNode.nat -> peerNode.nat) && (thisNode.censor -> peerNode.censor)) {
            ListenPort = port;
          });
        wireguardPeers = singleton (
          {
            PublicKey = peerNode.pub_key;
            AllowedIPs = [
              "::/0"
              "0.0.0.0/0"
            ];
            RouteTable = false;
          }
          // optionalAttrs (thisNode.nat || !peerNode.nat) {
            Endpoint =
              let
                port = toString peerPortsMap.${peerName};
                addr =
                  if ((thisNode.nat && peerNode.nat) || (thisNode.censor == peerNode.censor)) then
                    peerNode.addr
                  else
                    "127.0.0.1";
              in
              (addr + ":" + port);
          }
          // optionalAttrs thisNode.censor {
            PersistentKeepalive = 15;
          }
        );
      };
    };

in
{
  config = lib.mkIf cfg.enable {

    networking.firewall = { inherit allowedUDPPorts trustedInterfaces; };

    services.bird = {
      enable = true;
      config =
        let
          ifcs = concatMapStrings (n: ''
            interface "wg-${n}" {
                type ptmp;
                neighbors {
                    ${getAddrFromCIDR node.${n}.link_local_addr};
                };
            };
          '') (attrNames peerPortsMap);
        in
        ''
          log syslog all;
          debug protocols all;
          router id 10.0.0.${thisId};
          protocol device {}
          protocol direct {
              ipv6;
          };

          define SELFSET = [ fdcc::/64+ ];
          function is_self_net() -> bool
          {
            return net ~ SELFSET;
          }
          protocol kernel kernel_v6 {
           ipv6 {
             import none;
             export filter {
               if source = RTS_STATIC then reject;
               if net ~ SELFSET then {
                   krt_prefsrc = fdcc::${thisId};
               }
               accept;
             };
           };
          };

          protocol ospf v3 {
              area 0.0.0.0 {
              ${ifcs}
              };
          };
        '';
    };

    # it dont recursiveUpdate :\
    systemd.network.netdevs = (concatMapAttrs genPeerNetdev peerPortsMap);
    systemd.network.networks = (concatMapAttrs genPeerNetwork peerPortsMap);
  };
}
