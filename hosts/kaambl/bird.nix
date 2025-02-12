{
  services.bird = {
    enable = true;
    config = ''
      log syslog all;
      debug protocols all;
      router id 10.0.0.2;
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
               krt_prefsrc = fdcc::2;
           }
           accept;
         };
       };
      };
  
      protocol babel {
        interface "wg-*" {
          port 6696;
          type tunnel;
        };
       ipv6 {
          export where is_self_net();
        };
      };
    '';
  };
  
}
