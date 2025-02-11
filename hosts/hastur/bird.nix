{
  services.bird = {
    enable = true;
    config = ''
      log syslog all;
      debug protocols all;
      router id 10.0.0.1;
      protocol device {}
      protocol direct {
          ipv6;
          interface "eth0";
      };
      protocol kernel {
        ipv6 {
            export where proto = "wg";
        };
      };

      protocol babel {
        interface "wg-kaambl" {
          port 6696;
          type tunnel;
          rtt min 5ms;
          rtt max 256ms;
          rtt decay 120;
          extended next hop yes;
        };
        interface "wg-eihort" {
          port 6696;
          type tunnel;
          rtt min 500us;
          rtt max 256ms;
          rtt decay 32;
          extended next hop yes;
        };
        interface "wg-yidhra" {
          port 6696;
          type tunnel;
          rtt min 55ms;
          rtt max 256ms;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          port 6696;
          type tunnel;
          rtt min 160ms;
          rtt max 512ms;
          extended next hop yes;
        };
        interface "wg-azasos" {
          port 6696;
          type tunnel;
          rtt min 50ms;
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
