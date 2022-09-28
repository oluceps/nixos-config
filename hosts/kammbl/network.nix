{ config
, pkgs
, ...
}: {
  networking = {
    hostName = "kaambl"; # Define your hostname.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    enableIPv6 = true;
    interfaces.wan.wakeOnLan.enable = false;
    interfaces.wan.useDHCP = true;

    # interfaces.enp4s0.useDHCP = true;
    #  interfaces.wlp5s0.useDHCP = true;
    #
    # Configure network proxy if necessary
    # proxy.default = "http://127.0.0.1:7890";

    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = false;
    networkmanager.dns="systemd-resolved";
  };

  #  systemd.network.wait-online = {
  #    anyInterface = false;
  #    #ignoredInterfaces = [ "utun" "meta"  ];
  #  };

  systemd.network = {
    enable =true;

    links."10-wan" = {
      matchConfig.MACAddress = "20:47:47:0e:c8:66";
      linkConfig.Name = "wan";
    };

    links."20-wlan" = {
      matchConfig.MACAddress = "ac:d1:b8:d0:f4:f5";
      linkConfig.Name = "wlan";
    };
    networks = {
      "20-wireless" = {
        matchConfig.Name = "wlan";
        DHCP = "yes";
        #address = [ "192.168.0.10/24" ];
        #      dhcpV4Config.RouteMetric = 2048;
        #      dhcpV6Config.RouteMetric = 2048;
        #        routes = [
        #          { routeConfig = { Gateway = "192.168.0.9"; }; }
        #          #{routeConfig = {Gateway = "fe80::c609:38ff:fef2:3ecb";};}
        #        ];
        #        #dns = ["192.168.2.2" "fe80::c609:38ff:fef2:3ecb"];
           dns = [ "127.0.0.1:53" "::1" ];
      };
      #      enp4s0 = {
      #        name = "enp4s0";
      #        address = ["192.168.2.9/24"];
      #
      #        routes = [
      #          {routeConfig = {Gateway = "192.168.2.1";};}
      #        ];
      #        dns = ["223.6.6.6"];
      #
      #      };
    };
  };
}
