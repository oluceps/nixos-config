{ lib, config, ... }:
{
  services.babeld = {
    enable = true;
    config = ''
      skip-kernel-setup true
      local-path /var/run/babeld/ro.sock
      router-id fa:16:3e:d3:09:f8
      interface wg0 type tunnel rtt-max 512
      interface wg1 type tunnel rtt-max 512
      redistribute ip fdcc::/64 ge 64 le 128 local allow
      redistribute proto 42
      redistribute local deny
    '';
  };

  services.resolved = {
    enable = lib.mkForce false;
    llmnr = "false";
    dnssec = "false";
    extraConfig = ''
      MulticastDNS=off
    '';
    fallbackDns = [ "8.8.8.8#dns.google" ];
    # dnsovertls = "true";
  };
  networking.domain = "nyaw.xyz";
  networking = {
    timeServers = [
      "ntp.sjtu.edu.cn"
      "ntp1.aliyun.com"
      "ntp.ntsc.ac.cn"
      "cn.ntp.org.cn"
    ];
    nameservers = [
      "223.5.5.5#dns.alidns.com"
      "120.53.53.53#dot.pub"
    ];
    resolvconf.useLocalResolver = true;
    firewall = {
      enable = true;
      checkReversePath = false;
      trustedInterfaces = [
        "virbr0"
        "wg0"
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
        8448
        34197
        8083 # streaming
      ];
      allowedTCPPorts = [
        80
        443
        8080
        9900
        2222
        5173
        8448
        32193 # ss
        8083 # streaming
      ];
    };

    useNetworkd = true;
    useDHCP = false;

    hostName = "azasos"; # Define your hostname.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    enableIPv6 = true;
    nftables = {

      # interfaces.enp4s0.useDHCP = true;
      #  interfaces.wlp5s0.useDHCP = true;
      #
      # Configure network proxy if necessary
      # proxy.default = "http://127.0.0.1:7890";

      # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      enable = true;

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
      matchConfig.MACAddress = "fa:16:3e:d3:09:f8";
      linkConfig.Name = "eth0";
    };

    # hastur
    netdevs.wg0 = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = config.vaultix.secrets.wga.path;
        ListenPort = 51820;
        RouteTable = false;
      };
      wireguardPeers = [
        {
          PublicKey = "BCbrvvMIoHATydMkZtF8c+CHlCpKUy1NW+aP0GnYfRM=";
          AllowedIPs = [
            "::/0"
            "0.0.0.0/0"
          ];
          RouteTable = false;
          PersistentKeepalive = 15;
        }
      ];
    };

    networks."10-wg0" = {
      matchConfig.Name = "wg0";
      addresses = [
        {
          Address = "fdcc::3/128";
          Peer = "fdcc::1/128";
        }
        {
          Address = "fe80::216:3eff:fe7b:d228/64";
          Peer = "fe80::216:3eff:fe0f:37d8/64";
          Scope = "link";
        }
      ];
      networkConfig = {
        DHCP = false;
      };
    };

    # abhoth
    netdevs.wg1 = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg1";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = config.vaultix.secrets.wga.path;
        ListenPort = 51821;
        RouteTable = false;
      };
      wireguardPeers = [
        {
          PublicKey = "jQGcU+BULglJ9pUz/MmgOWhGRjpimogvEudwc8hMR0A=";
          AllowedIPs = [
            "::/0"
            "0.0.0.0/0"
          ];
          Endpoint = "172.234.92.148:51821";
          RouteTable = false;
        }
      ];
    };

    networks."10-wg1" = {
      matchConfig.Name = "wg1";
      addresses = [
        {
          Address = "fdcc::3/128";
          Peer = "fdcc::2/128";
        }
        {
          Address = "fe80::216:3eff:fe7b:d228/64";
          Peer = "fe80::216:3eff:fe15:ec52/64";
          Scope = "link";
        }
      ];
      networkConfig = {
        DHCP = false;
      };
    };

    networks."20-wired" = {
      matchConfig.Name = "eth0";
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 2046;
      dhcpV6Config.RouteMetric = 2046;
      networkConfig = {
        # Bond = "bond1";
        # PrimarySlave = true;
        DNSSEC = true;
        MulticastDNS = true;
        DNSOverTLS = true;
      };
      # # REALLY IMPORTANT
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
    };
  };
}
