{
  inputs,
  ...
}:
{
  flake.modules.nixos.limes =
    { ... }:
    {

      imports = [ inputs.limes.nixosModules.default ];
      services.limes = {
        enable = true;
        settings = {
          core = {
            log_level = "debug";
          };
          routing = {
            fwmark = "0x100";
            table_id = 100;
            tproxy_port = 12345;
          };
          rules = {
            proxy = {
              programs = [
                "git"
              ];
              cgroups = [
                "proxy.slice"
                "user.slice/user-1000.slice/user@1000.service/proxy.slice"
                "system.slice/system-nix\\x2ddaemon.slice"
                "system.slice/sing-box.service"
                "system.slice/xray.service"
              ];
            };
            bypass = {
              programs = [
                "sing-box"
                "xray"
                "ss-local"
              ];
            };
          };
        };
      };

    };
}
