{ lib, config, ... }: {
  networking.resolvconf.useLocalResolver = true;
  networking = {
    hostName = "hastur"; # Define your hostname.
    # replicates the default behaviour.
    enableIPv6 = true;
    interfaces.wan.wakeOnLan.enable = true;
    wireless.iwd.enable = true;
    useNetworkd = true;
    useDHCP = false;
    firewall = {
      enable = true;
      trustedInterfaces = [ "virbr0" "wg0" ];
      allowedUDPPorts = [ 8080 5173 51820 9918 ];
      allowedTCPPorts = [ 8080 9900 2222 5173 ];
    };
    nftables.enable = true;
    networkmanager.enable = lib.mkForce false;
  };
  systemd.network = {
    enable = true;

    wait-online = {
      enable = true;
      anyInterface = true;
      ignoredInterfaces = [ "wlan" "wg0" ];
    };

    links."10-wan" = {
      matchConfig.MACAddress = "3c:7c:3f:22:49:80";
      linkConfig.Name = "wan";
    };

    links."30-rndis" = {
      matchConfig.Driver = "rndis_host";
      linkConfig = {
        NamePolicy = "keep";
        Name = "rndis";
        MACAddressPolicy = "persistent";
      };
    };
    links."40-wlan" = {
      matchConfig.MACAddress = "70:66:55:e7:1c:b1";
      linkConfig.Name = "wlan";
    };

    netdevs = {
      wg0 = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg.path;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "+fuA9nUmFVKy2Ijfh5xfcnO9tpA/SkIL4ttiWKsxyXI=";
              AllowedIPs = [ "10.0.0.0/24" ];
              Endpoint = "146.190.121.75:51820";
              PersistentKeepalive = 25;
            };
          }
        ];
      };
    };


    networks = {
      "10-wg0" = {
        matchConfig.Name = "wg0";
        # IP addresses the client interface will have
        address = [
          "10.0.0.2/24"
        ];
        DHCP = "no";
        # dns = [ "fc00::53" ];
        # ntp = [ "fc00::123" ];
        # gateway = [
        # "fc00::1"
        # "10.0.0.1"
        # ];
        # networkConfig = {
        #   IPv6AcceptRA = false;
        # };
      };

      "20-wired" = {
        matchConfig.Name = "wan";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 2046;
        dhcpV6Config.RouteMetric = 2046;
        # address = [ "192.168.0.2/24" ];
        networkConfig = {
          DNSSEC = true;
          MulticastDNS = true;
          DNSOverTLS = true;
        };
        # REALLY IMPORTANT
        dhcpV4Config.UseDNS = false;
        dhcpV6Config.UseDNS = false;

        # routes = [
        # { routeConfig = { Gateway = "192.168.0.1"; }; }
        # { routeConfig = { Gateway = "fe80::c609:38ff:fef2:3ecb"; }; }
        # ];
        # dns = [ "::1" ];
        # "::1"
      };

      "30-rndis" = {
        matchConfig.Name = "rndis";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 2044;
        dhcpV6Config.RouteMetric = 2044;
        dhcpV4Config.UseDNS = false;
        dhcpV6Config.UseDNS = false;
        # dns = [ "::1" ];
        networkConfig = {
          DNSSEC = true;
        };
      };

      "40-wireless" = {
        matchConfig.Name = "wlan";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 2048;
        dhcpV6Config.RouteMetric = 2048;
        dhcpV4Config.UseDNS = false;
        dhcpV6Config.UseDNS = false;
        # dns = [ "::1" ];
      };

    };
  };
}
