{
  flake.modules.nixos.plugIn =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.plugIn;
      thisNode = config.data.node.${config.networking.hostName};
    in
    {
      options.plugIn = {
        enable = lib.mkEnableOption "Common plugins and network settings";
      };

      config = lib.mkIf cfg.enable {
        networking.firewall = {
          trustedInterfaces = [
            "xfrm-*"
            "hts-0"
          ];
        };

        networking.nftables.tables.filter = {
          family = "inet";
          content = ''
            chain forward {
              type filter hook forward priority filter; policy accept;
              
              oifname "hts-0" tcp flags & (syn | rst) == syn tcp option maxseg size set rt mtu
              iifname "hts-0" tcp flags & (syn | rst) == syn tcp option maxseg size set rt mtu
            }
          '';
        };

        # Repacked modules are now part of flake.modules.nixos
        # These are enabled here if plugIn is enabled
        services.yggdrasil.enable = true;
        # services.vxlan-mesh.enable = true; # vxlan-mesh doesn't have a simple enable option, it's a bundle
      };
    };
}
