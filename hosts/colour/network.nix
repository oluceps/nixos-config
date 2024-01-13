{ lib
, ...
}: {
  networking = {
    resolvconf.useLocalResolver = true;
    firewall = {
      checkReversePath = false;
      enable = true;
      trustedInterfaces = [ "virbr0" "wg0" "wg1" ];
      allowedUDPPorts = [ 80 443 8080 5173 23180 4444 51820 ];
      allowedTCPPorts = [ 80 443 8080 9900 2222 5173 8448 ];
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

    netdevs = { };

    networks = {
      "20-wired" = {
        matchConfig.Name = "eth0";
        DHCP = "yes";
      };
    };
  };
}
