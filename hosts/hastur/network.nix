{ config
, pkgs
, ...
}: {
  networking = {
    hostName = "hastur"; # Define your hostname.
    # replicates the default behaviour.
    enableIPv6 = true;
    interfaces.wan.wakeOnLan.enable = true;
    wireless.iwd.enable = true;
    useDHCP = false;
    # Configure network proxy if necessary
    # proxy.default = "http://127.0.0.1:7890";
    networkmanager.enable = false;

    #    wireguard.interfaces = {
    #      wg0 = {
    #        ips = [ "172.16.0.2/32" "fd01:5ca1:ab1e:88ba:9158:7ec7:1f13:7535/128" ];
    #        listenPort = 51820;
    #        privateKeyFile = "/home/riro/.config/wg/key";
    #        peers = [
    #          {
    #            #             Public key of the server (not a file path).
    #            publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
    #
    #            #          Forward all the traffic via VPN.
    #            allowedIPs = [ "0.0.0.0/1" "::/1" ];
    #            #           Or forward only particular subnets
    #            #           allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];
    #
    #            #            Set this to the server IP and port.
    #            endpoint = "engage.cloudflareclient.com:2408"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuardLoop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577
    #
    #            #             Send keepalives every 25 seconds. Important to keep NAT tables alive.
    #            persistentKeepalive = 25;
    #          }
    #        ];
    #      };
    #    };
  };
  systemd.network = {
    enable = true;

    links."10-wan" = {
      matchConfig.MACAddress = "3c:7c:3f:22:49:80";
      linkConfig.Name = "wan";
    };
    networks = {
      "20-wired" = {
        matchConfig.Name = "wan";
        DHCP = "no";
        address = [ "192.168.0.9/24" ];
        #      dhcpV4Config.RouteMetric = 2048;
        #      dhcpV6Config.RouteMetric = 2048;
              routes = [
                { routeConfig = { Gateway = "192.168.0.1"; }; }
        #{routeConfig = {Gateway = "fe80::c609:38ff:fef2:3ecb";};}
              ];
        #dns = ["192.168.2.2" "fe80::c609:38ff:fef2:3ecb"];
        #        dns = [ "127.0.0.1:53" "::1" ];
      };
    };
  };
}
