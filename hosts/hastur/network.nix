{ ... }: {
  environment.etc."resolv.conf".text = ''
    nameserver 223.6.6.6
    nameserver 8.8.8.8
  '';
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
      trustedInterfaces = [ "virbr0" ];
      allowedUDPPorts = [ 8080 9000 9001 ];
      allowedTCPPorts = [ 8080 9000 ];
    };
    nftables.enable = true;
    networkmanager.enable = false;



    # wireguard.interfaces = {
    #   wg0 = {
    #     ips = [ "172.16.0.2/32" "fd01:5ca1:ab1e:88ba:9158:7ec7:1f13:7535/128" ];
    #     listenPort = 51820;
    #     privateKeyFile = config.rekey.secrets.wg.path;
    #     peers = [
    #       {
    #         # Public key of the server (not a file path).
    #         publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";

    #         # Forward all the traffic via VPN.
    #         allowedIPs = [ "172.16.0.0/24" ];
    #         # Or forward only particular subnets
    #         # allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

    #         # Set this to the server IP and port.
    #         endpoint = "162.159.192.8:2408"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuardLoop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

    #         # Send keepalives every 25 seconds. Important to keep NAT tables alive.
    #         persistentKeepalive = 25;
    #       }
    #     ];
    #   };
    # };
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


    networks = {
      "20-wired" = {
        matchConfig.Name = "wan";
        DHCP = "no";
        dhcpV4Config.RouteMetric = 2046;
        dhcpV6Config.RouteMetric = 2046;
        address = [ "192.168.0.2/24" ];
        routes = [
          { routeConfig = { Gateway = "192.168.0.1"; }; }
          # { routeConfig = { Gateway = "fe80::c609:38ff:fef2:3ecb"; }; }
        ];
        # "::1"
      };

      "30-rndis" = {
        matchConfig.Name = "rndis";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 2044;
        dhcpV6Config.RouteMetric = 2044;
      };

      "40-wireless" = {
        matchConfig.Name = "wlan";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 2048;
        dhcpV6Config.RouteMetric = 2048;
      };

    };
  };
}
