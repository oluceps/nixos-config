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
      allowedTCPPorts = [ 80 443 8080 9900 2222 5173 8448 1935 1985 10080 8000 ];
    };

    useNetworkd = true;
    useDHCP = false;

    hostName = "colour";
    enableIPv6 = true;

    nftables.enable = true;
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
      matchConfig.MACAddress = "00:22:48:67:8d:4a";
      linkConfig.Name = "eth0";
    };

    netdevs = {
      wg0 = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wga.path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "BCbrvvMIoHATydMkZtF8c+CHlCpKUy1NW+aP0GnYfRM=";
              AllowedIPs = [ "10.0.2.2/32" ];
              PersistentKeepalive = 15;
            };
          }
          {
            wireguardPeerConfig = {
              PublicKey = "i7Li/BDu5g5+Buy6m6Jnr09Ne7xGI/CcNAbyK9KKbQg=";
              AllowedIPs = [ "10.0.2.3/32" ];
              PersistentKeepalive = 15;
            };
          }

          {
            wireguardPeerConfig = {
              PublicKey = "PkprQcw4kYLiX1Ix8FcIje1x0yie/gjheX7UbxQ7OUw=";
              AllowedIPs = [ "10.0.2.4/32" ];
              PersistentKeepalive = 15;
            };
          }

          {
            wireguardPeerConfig = {
              PublicKey = "TcqM0iPp4Dw1IceB88qw/hSiPWXAzT9GECVT36eyzgc=";
              AllowedIPs = [ "10.0.2.6/32" ];
              PersistentKeepalive = 15;
            };
          }

          {
            wireguardPeerConfig = {
              PublicKey = "kDWOvV5AJ++zRQeTn12kd9x45JvxNqnwhPnB9HkzK0c=";
              PersistentKeepalive = 15;
            };
          }

          {
            wireguardPeerConfig = {
              PublicKey = "83NjKIMSJxSorKEhxbD8lEu0Xa9rbAyGkRD77xsTsWQ=";
              AllowedIPs = [ "10.0.2.15/32" ];
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
          "10.0.2.1/24"
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
