{
  flake.modules.nixos.consul =
    { config, lib, ... }:
    let
      domain = "mesh.nyaw.xyz";
      serverNames = [
        "eihort"
        "abhoth"
        "nodens"
      ];
      hostName = config.networking.hostName;
      server = builtins.elem hostName serverNames;
      serverAddresses = map (name: config.data.node.${name}.unique_addr_nomask) serverNames;

      # Custom negative anchors replace systemd's built-in private zones.
      privateZones = [
        "test"
        "10.in-addr.arpa"
        "168.192.in-addr.arpa"
        "d.f.ip6.arpa"
        "local"
        "home"
        "corp"
        "lan"
        "intranet"
        "internal"
        "private"
        "home.arpa"
        "resolver.arpa"
        "ipv4only.arpa"
        "170.0.0.192.in-addr.arpa"
        "171.0.0.192.in-addr.arpa"
      ]
      ++ map (n: "${toString n}.172.in-addr.arpa") (lib.range 16 31);
    in
    {
      nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "consul";

      realm.serviceDiscovery = {
        enable = true;
        address = config.data.node.${hostName}.unique_addr_nomask;
      };

      services.consul = {
        forceAddrFamily = "ipv6";
        interface = {
          bind = "anchor-0";
          advertise = "anchor-0";
        };
        extraConfig = {
          inherit domain server;
          datacenter = "nyaw";
          node_name = hostName;
          client_addr = "127.0.0.1";
          retry_join = serverAddresses;
          dns_config.only_passing = true;
          connect.enabled = false;
        }
        // lib.optionalAttrs server {
          bootstrap_expect = builtins.length serverNames;
        };
      };

      # The upstream pre-start script writes addresses through this symlink.
      environment.etc."consul-addrs.json".source = "/run/consul/addrs.json";
      systemd.services.consul.serviceConfig.RuntimeDirectory = "consul";

      services.resolved = {
        enable = true;
        dnsDelegates.mesh.Delegate = {
          DNS = [ "127.0.0.1:8600" ];
          Domains = [ "~${domain}" ];
          DefaultRoute = false;
        };
      };

      environment.etc."dnssec-trust-anchors.d/consul.negative".text =
        lib.concatStringsSep "\n" (privateZones ++ [ domain ]) + "\n";

      systemd.services.systemd-resolved.reloadTriggers = [
        config.environment.etc."dnssec-trust-anchors.d/consul.negative".source
      ];
    };
}
