{
  services.bird = {
    enable = true;
    config = ''
      log syslog all;
      debug protocols all;
      router id 10.0.0.4;
      protocol device {}
      protocol direct {
          ipv6;
      };
      protocol babel {
        interface "wg-kaambl" {
          port 6696;
          type tunnel;
          rtt min 70ms;
          rtt max 256ms;
          rtt decay 120;
          extended next hop yes;
        };
        interface "wg-eihort" {
          port 6696;
          type tunnel;
          rtt min 45ms;
          rtt max 256ms;
          rtt decay 60;
          extended next hop yes;
        };
        interface "wg-hastur" {
          port 6696;
          type tunnel;
          rtt min 55ms;
          rtt max 256ms;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          port 6696;
          type tunnel;
          rtt min 64ms;
          rtt max 256ms;
          extended next hop yes;
        };
        interface "wg-azasos" {
          port 6696;
          type tunnel;
          rtt min 40ms;
          rtt max 512ms;
          extended next hop yes;
        };
        ipv6 {
          export where (source = RTS_DEVICE) || (source = RTS_BABEL);
        };
      };
    '';
  };
  
}
