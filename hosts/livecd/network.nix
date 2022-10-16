{ config
, pkgs
, ...
}: {
  networking = {
    hostName = "livecd"; # Define your hostname.
    # replicates the default behaviour.
    enableIPv6 = true;
    # Configure network proxy if necessary
    # proxy.default = "http://127.0.0.1:7890";

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
}
