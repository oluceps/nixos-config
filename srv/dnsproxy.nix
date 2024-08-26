{ ... }:
{
  enable = true;
  flags = [
    "--cache"
    "--upstream-mode parallel"
    "--edns"
    "--http3"
    "--ipv6-disabled" # :(
  ];
  settings = {
    bootstrap = [ "223.6.6.6:53" ];
    listen-addrs = [ "0.0.0.0" ];
    listen-ports = [ 53 ];
    upstream = [
      "quic://dns.alidns.com"
      "tls://dot.pub"
      "tcp://223.5.5.5"
    ];
  };
}
