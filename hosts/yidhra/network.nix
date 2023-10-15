{ config
, pkgs
, lib
, ...
}: {
  services.mosdns.enable = true;
  networking = {
    resolvconf.useLocalResolver = true;
    firewall = {
      checkReversePath = false;
      enable = true;
      trustedInterfaces = [ "virbr0" "wg0" "wg1" ];
      allowedUDPPorts = [ 80 443 8080 5173 ];
      allowedTCPPorts = [ 80 443 8080 9900 2222 5173 ];
    };

    wireless.iwd.enable = true;
    useNetworkd = true;
    useDHCP = false;

    hostName = "yidhra"; # Define your hostname.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    enableIPv6 = true;

    # interfaces.enp4s0.useDHCP = true;
    #  interfaces.wlp5s0.useDHCP = true;
    #
    # Configure network proxy if necessary
    # proxy.default = "http://127.0.0.1:7890";

    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    nftables.enable = true;
    networkmanager.enable = lib.mkForce false;
    networkmanager.dns = "none";

  };
  systemd.network = {
    enable = true;

    wait-online = {
      enable = true;
      anyInterface = true;
      ignoredInterfaces = [ "wlan" "wg0" "wg1" ];
    };


    netdevs = {

      wg1 = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg1";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wgy.path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "BCbrvvMIoHATydMkZtF8c+CHlCpKUy1NW+aP0GnYfRM=";
              AllowedIPs = [ "10.0.1.2/32" ];
              PersistentKeepalive = 15;
            };
          }
          {
            wireguardPeerConfig = {
              PublicKey = "i7Li/BDu5g5+Buy6m6Jnr09Ne7xGI/CcNAbyK9KKbQg=";
              AllowedIPs = [ "10.0.1.3/32" ];
              PersistentKeepalive = 15;
            };
          }
        ];
      };
    };


    networks = {
      "10-wg1" = {
        matchConfig.Name = "wg1";
        address = [
          "10.0.1.1/24"
        ];
        networkConfig = {
          IPMasquerade = "ipv4";
          IPForward = true;
        };
      };

      # LACK output
    };
  };
}
