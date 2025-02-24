{
  repack.bird = {
    enable = true;
    config = ''
      protocol babel {
        # interface "wg-hastur" {
        #   type tunnel;
        #   rtt min 10ms;
        #   rtt max 256ms;
        #   rtt decay 90;
        #   hello interval 1s;
        #   update interval 4s;
        #   extended next hop yes;
        # };
        # interface "wg-eihort" {
        #   type tunnel;
        #   rtt min 5ms;
        #   rtt max 256ms;
        #   rtt decay 90;
        #   hello interval 1s;
        #   update interval 4s;
        #   extended next hop yes;
        # };
        interface "wg-yidhra" {
          type tunnel;
          rtt min 38ms;
          rtt max 256ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          type tunnel;
          rtt min 77ms;
          rtt max 256ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-azasos" {
          type tunnel;
          rtt min 33ms;
          rtt max 256ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        ipv6 {
          export filter intranet;
        };
      };
    '';
  };

}
