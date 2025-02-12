{
  services.bird = {
    enable = true;
    config = ''
      log syslog all;
      debug protocols all;
      router id 10.0.0.6;
      protocol device {}
      protocol direct {
          ipv6;
      };
      define SELFSET = [ fdcc::/64+ ];
      function is_self_net() -> bool
      {
        return net ~ SELFSET;
      }
      protocol kernel kernel_v6 {
       ipv6 {
         import none;
         export filter {
           if source = RTS_STATIC then reject;
           if net ~ SELFSET then {
               krt_prefsrc = fdcc::6;
           }
           accept;
         };
       };
      };


      protocol babel {
        interface "wg-kaambl" {
          port 6696;
          type tunnel;
          rtt min 94ms;
          rtt max 256ms;
          rtt decay 68;
          extended next hop yes;
        };
        interface "wg-eihort" {
          port 6696;
          type tunnel;
          rtt min 40ms;
          rtt max 380ms;
          rtt decay 60;
          extended next hop yes;
        };
        interface "wg-hastur" {
          port 6696;
          type tunnel;
          rtt min 45ms;
          rtt max 256ms;
          extended next hop yes;
        };
        interface "wg-yidhra" {
          port 6696;
          type tunnel;
          rtt min 40ms;
          rtt max 256ms;
          extended next hop yes;
        };
        interface "wg-abhoth" {
          port 6696;
          type tunnel;
          rtt min 95ms;
          rtt max 256ms;
          extended next hop yes;
        };
        ipv6 {
          export where is_self_net();
        };
      };
    '';
  };

}
