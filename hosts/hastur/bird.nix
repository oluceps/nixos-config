{
  repack.bird = {
    enable = true;
    config = ''
      protocol babel {
        interface "wg-kaambl" {
          type tunnel;
          rtt min 5ms;
          rtt max 256ms;
          rtt decay 120;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-eihort" {
          type tunnel;
          rtt min 500us;
          rtt max 256ms;
          rtt decay 32;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-yidhra" {
          type tunnel;
          rtt min 55ms;
          rtt max 256ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          type tunnel;
          rtt min 160ms;
          rtt max 512ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-azasos" {
          type tunnel;
          rtt min 50ms;
          rtt max 512ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        ipv6 {
          export where is_self_net();
        };
      };
    '';
  };

}
