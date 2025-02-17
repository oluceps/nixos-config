{
  repack.bird = {
    enable = true;
    config = ''
      protocol babel {
        interface "wg-kaambl" {
          type tunnel;
          rtt min 210ms;
          rtt max 512ms;
          rtt decay 120;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-eihort" {
          type tunnel;
          rtt min 170ms;
          rtt max 380ms;
          rtt decay 60;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-hastur" {
          type tunnel;
          rtt min 160ms;
          rtt max 256ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-yidhra" {
          type tunnel;
          rtt min 64ms;
          rtt max 256ms;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        interface "wg-azasos" {
          type tunnel;
          rtt min 50ms;
          rtt max 256ms;
          rtt decay 60;
          hello interval 1s;
          update interval 4s;
          extended next hop yes;
        };
        ipv6 {
          export where is_intranet();
        };
      };
    '';
  };

}
