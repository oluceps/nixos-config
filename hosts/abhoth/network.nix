{ config, lib, ... }:
{
  services.babeld = {
    enable = true;
    extraConfig = ''
      router-id f2:3c:95:50:a1:73
      interface wg0 type tunnel rtt-max 512
      redistribute ip fdcc::/64 ge 64 le 128 local allow
      redistribute proto 42
      redistribute local deny
    '';
  };
  services = {
    resolved.enable = lib.mkForce false;
  };
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
  '';
  networking = {
    domain = "nyaw.xyz";
    # resolvconf.useLocalResolver = true;
    firewall = {
      checkReversePath = false;
      enable = true;
      trustedInterfaces = [
        "virbr0"
        "wg*"
      ];
      allowedUDPPortRanges = [
        {
          from = 51820;
          to = 51830;
        }
      ];
      allowedUDPPorts = [
        80
        443
        8080
        5173
        23180
        4444
        3330
        8880
        34197 # factorio realm
      ];
      allowedTCPPorts = [
        80
        443
        8080
        9900
        2222
        5173
        8448
        3330
        8880
        40119 # stls
      ];
    };

    useNetworkd = true;
    useDHCP = false;

    hostName = "abhoth";
    enableIPv6 = false;

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
      ignoredInterfaces = [
        "wg0"
      ];
    };

    links."10-eth0" = {
      matchConfig.MACAddress = "f2:3c:95:50:77:31";
      linkConfig.Name = "eth0";
    };

    netdevs.wg0 = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = config.vaultix.secrets.wgab.path;
        ListenPort = 51820;
        RouteTable = false;
      };
      wireguardPeers = [
        {
          PublicKey = "BCbrvvMIoHATydMkZtF8c+CHlCpKUy1NW+aP0GnYfRM=";
          AllowedIPs = [ "::/0" ];
          RouteTable = false;
        }
      ];
    };

    networks."10-wg0" = {
      matchConfig.Name = "wg0";
      addresses = [
        {
          Address = "fdcc::2/128";
          Peer = "fdcc::1/128";
        }
        {
          Address = "fe80::216:3eff:fe15:ec52/64";
          Peer = "fe80::216:3eff:fe0f:37d8/64";
          Scope = "link";
        }
      ];
      networkConfig = {
        DHCP = false;
      };
    };

    # azasos
    netdevs.wg2 = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg2";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = config.vaultix.secrets.wgab.path;
        ListenPort = 51821;
        RouteTable = false;
      };
      wireguardPeers = [
        {
          PublicKey = "49xNnrpNKHAvYCDikO3XhiK94sUaSQ4leoCnTOQjWno=";
          AllowedIPs = [ "::/0" ];
          RouteTable = false;
        }
      ];
    };

    networks."10-wg2" = {
      matchConfig.Name = "wg2";
      addresses = [
        {
          Address = "fdcc::2/128";
          Peer = "fdcc::3/128";
        }
        {
          Address = "fe80::216:3eff:fe15:ec52/64";
          Peer = "fe80::216:3eff:fe7b:d228/64";
          Scope = "link";
        }
      ];
      networkConfig = {
        DHCP = false;
      };
    };

    networks."20-eth0" = {
      matchConfig.Name = "eth0";
      DHCP = "yes";
    };

  };
}
