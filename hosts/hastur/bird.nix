{
  services.bird = {
    enable = true;
    config = ''
      log syslog all;
      debug protocols all;
      timeformat protocol iso long;
      router id 10.0.0.1;
      protocol device {}
      protocol direct {
          ipv6;
      };
      define SELFSET = [ fdcc::/64+ ];

      function is_self_net() -> bool
      {
        return net ~ SELFSET;
      }

      protocol kernel {
        ipv6 {
          import none;
          export filter {
            if source = RTS_STATIC then reject;
            accept;
          };
        };
      };
      protocol babel {
        interface "wg-kaambl" {
          port 6696;
          type tunnel;
          rtt min 5ms;
          rtt max 256ms;
          rtt decay 120;
          update interval 8s;
          extended next hop yes;
        };
        interface "wg-eihort" {
          port 6696;
          type tunnel;
          rtt min 500us;
          rtt max 256ms;
          rtt decay 32;
          update interval 8s;
          extended next hop yes;
        };
        interface "wg-yidhra" {
          port 6696;
          type tunnel;
          rtt min 55ms;
          rtt max 256ms;
          update interval 8s;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          port 6696;
          type tunnel;
          rtt min 160ms;
          rtt max 512ms;
          update interval 8s;
          extended next hop yes;
        };
        interface "wg-azasos" {
          port 6696;
          type tunnel;
          rtt min 50ms;
          rtt max 512ms;
          update interval 8s;
          extended next hop yes;
        };
        ipv6 {
          export where is_self_net();
        };
      };
    '';
  };
  
}
