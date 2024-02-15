{ lib
, config
, ...
}: {
  networking = {
    resolvconf.useLocalResolver = true;
    firewall = {
      checkReversePath = false;
      enable = true;
      trustedInterfaces = [ "virbr0" "wg0" "wg1" ];
      allowedUDPPorts = [ 80 443 8080 5173 23180 4444 51820 1935 1985 10080 8000 ];
      allowedTCPPorts = [ 80 443 8080 9900 2222 5173 8448 1935 1985 10080 8000 9000 9001 ];
    };
    hostId = "0bc55a2e";
    useNetworkd = true;
    useDHCP = false;

    hostName = "eihort";
    enableIPv6 = true;
    nftables = {
      enable = true;
      # for hysteria port hopping
      ruleset = ''
        table ip nat {
        	chain prerouting {
        		type nat hook prerouting priority filter; policy accept;
        		iifname "eth0" udp dport 40000-50000 counter packets 0 bytes 0 dnat to :4432
        	}
        }
        table ip6 nat {
        	chain prerouting {
        		type nat hook prerouting priority filter; policy accept;
        		iifname "eth0" udp dport 40000-50000 counter packets 0 bytes 0 dnat to :4432
        	}
        }
      '';
    };
    networkmanager.enable = lib.mkForce false;
    networkmanager.dns = "none";

  };
  systemd.network = {
    enable = true;

    wait-online = {
      enable = true;
      anyInterface = true;
      ignoredInterfaces = [ "wg0" "wg1" ];
    };

    links."eth0" = {
      matchConfig.MACAddress = "40:16:7e:33:cf:fd";
      linkConfig.Name = "eth0";
    };
    links."eth1" = {
      matchConfig.MACAddress = "40:16:7e:33:cf:fe";
      linkConfig.Name = "eth1";
    };

    netdevs = {

      wg0 = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wge.path;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "ANd++mjV7kYu/eKOEz17mf65bg8BeJ/ozBmuZxRT3w0=";
              AllowedIPs = [ "10.0.0.0/24" ];
              Endpoint = "47.155.210.51:51820";
              PersistentKeepalive = 15;
            };
          }
        ];
      };
    };

    networks = {

      "10-wg0" = {
        matchConfig.Name = "wg0";
        address = [
          "10.0.0.6/24"
        ];
        networkConfig = {
          IPMasquerade = "ipv4";
          IPForward = true;
        };
      };

      "20-wired" = {
        matchConfig.Name = "eth0";
        DHCP = "yes";

      };
    };
  };
}
