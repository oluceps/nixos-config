{
  repack.bird = {
    enable = true;
    config = ''
      protocol babel {
        interface "wg-*" {
          type tunnel;
          hello interval 1s;
          update interval 2s;
          rtt decay 60;
          check link no;
          extended next hop yes;
        };
        # interface "wg-kaambl" {
        #   rtt min 5ms;
        #   rtt max 256ms;
        #   rtt decay 120;
        # };
        interface "wg-eihort" {
          rtt min 500us;
          rtt max 256ms;
          rtt decay 52;
        };
        interface "wg-yidhra" {
          rtt min 55ms;
          rtt max 256ms;
        };
        interface "wg-abhoth" {
          rtt min 160ms;
          rtt max 512ms;
          rtt decay 180;
        };
        interface "wg-azasos" {
          rtt min 50ms;
          rtt max 512ms;
        };
        ipv6 {
          export filter intranet;
        };
      };
    '';
  };

}
