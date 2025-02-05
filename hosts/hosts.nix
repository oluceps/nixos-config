let
  common = {
    "116.196.112.43" = [ "azasos.nyaw.xyz" ];
    "172.234.92.148" = [ "abhoth.nyaw.xyz" ];
    "8.210.47.13" = [ "yidhra.nyaw.xyz" ];
  };

  srvOnEihort = [
    "eihort.nyaw.xyz"
    "matrix.nyaw.xyz"
    "photo.nyaw.xyz"
    "s3.nyaw.xyz"
  ];

  lan = {
    "192.168.1.16" = srvOnEihort;
    "192.168.1.2" = [
      "hastur.nyaw.xyz"
    ];
    "192.168.1.187" = [ "kaambl.nyaw.xyz" ];
  };

  remote = {
    "fdcc::3" = srvOnEihort;
    "fdcc::1" = [
      "hastur.nyaw.xyz"
    ];
    "fdcc::2" = [ "kaambl.nyaw.xyz" ];
  };

  sum = lan // common;
in
{
  kaambl = {
    "127.0.0.1" = [
      "kaambl.nyaw.xyz"
      "dns.nyaw.xyz"
    ];
  } // sum;
  hastur = {
    "127.0.0.1" = [
      "hastur.nyaw.xyz"
    ];
  } // sum;
  eihort = {
  } // sum;
}
