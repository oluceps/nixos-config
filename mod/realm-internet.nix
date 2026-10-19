{
  flake.modules.nixos.realm-internet =
    { ... }:
    {
      services.squid = {
        enable = true;
        configText = ''
          http_port 127.0.0.1:3128
          acl CONNECT method CONNECT
          acl Safe_ports port 80 443
          acl SSL_ports port 443
          acl local_clients src 127.0.0.1/32
          acl private_dst dst 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.168.0.0/16 198.18.0.0/15 224.0.0.0/4 240.0.0.0/4 ::/128 ::1/128 200::/7 fc00::/7 fe80::/10 ff00::/8
          http_access deny !Safe_ports
          http_access deny CONNECT !SSL_ports
          http_access deny private_dst
          http_access allow local_clients
          http_access deny all
          cache deny all
          cache_effective_user squid
          pid_filename /run/squid.pid
          cache_log stdio:/var/log/squid/cache.log
          access_log none
          cache_store_log none
        '';
      };
      realm.workloads.internet = {
        unit = "squid.service";
        user = "squid";
        group = "squid";
        runtime = "external";
        isolation.privateNetwork = false;
        ingress.http = {
          port = 19328;
          target = "127.0.0.1:3128";
          hostLoopback = true;
          consulService = "internet-proxy";
          allowedIDs = [
            "spiffe://nyaw.xyz/service/misskey"
            "spiffe://nyaw.xyz/service/grafana"
          ];
        };
      };
    };
}
