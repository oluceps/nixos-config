{ ... }:
{
  enable = true;
  flags = [
    "--cache"
    "--edns"
    "--http3"
    "--ipv6-disabled" # :(
  ];
  settings = {
    bootstrap = [ "tcp://223.6.6.6:53" ];
    listen-addrs = [ "0.0.0.0" ];
    listen-ports = [ 53 ];
    upstream-mode = "parallel";
    upstream = [
      "quic://dns.alidns.com"
      "tls://dot.pub"
      "h3://dns.google/dns-query"
    ];
  };
}
