{
  services.bird = {
    enable = true;
    config = ''
      router id 10.0.0.3;
      protocol babel {
        interface "wg-kaambl" {
          port 6696;
          type tunnel;
          rtt min 20ms;
          rtt max 256ms;
          rtt decay 32;
          extended next hop yes;
        };
        interface "wg-hastur" {
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
          rtt min 50ms;
          rtt max 256ms;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          port 6696;
          type tunnel;
          rtt min 160ms;
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
