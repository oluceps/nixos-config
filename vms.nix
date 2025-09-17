{
  withSystem,
  self,
  inputs,
  ...
}:
{

  perSystem =
    { pkgs, ... }:
    {
      packages.sep-microvm = self.nixosConfigurations.sep-microvm.config.microvm.declaredRunner;
    };
  flake = {
    nixosConfigurations = {
      sep-microvm = withSystem "x86_64-linux" (
        {
          system,
          ...
        }:
        self.lib.nixosSystem (
          let
            # Change this by VM!
            index = 1;
            mac = "00:00:00:00:00:01";
          in
          {
            inherit system;
            modules = [
              inputs.microvm.nixosModules.microvm
              {
                networking.hostName = "sep-microvm";
                networking.useNetworkd = true;
                systemd.network.networks."10-eth" = {
                  matchConfig.MACAddress = mac;
                  # Static IP configuration
                  address = [
                    "10.255.0.${toString index}/32"
                    "fec0::${self.lib.toHexString index}/128"
                  ];
                  routes = [
                    {
                      # A route to the host
                      Destination = "10.255.0.0/32";
                      GatewayOnLink = true;
                    }
                    {
                      # Default route
                      Destination = "0.0.0.0/0";
                      Gateway = "10.255.0.0";
                      GatewayOnLink = true;
                    }
                    {
                      # Default route
                      Destination = "::/0";
                      Gateway = "fec0::";
                      GatewayOnLink = true;
                    }
                  ];
                  networkConfig = {
                    # DNS servers no longer come from DHCP nor Router
                    # Advertisements. Perhaps you want to change the defaults:
                    DNS = [
                      "223.5.5.5"
                    ];
                  };
                };
                users.users.root.password = "";
                microvm = {
                  interfaces = [
                    {
                      id = "vm${toString index}";
                      type = "tap";
                      inherit mac;
                    }
                  ];

                  volumes = [
                    {
                      mountPoint = "/var";
                      image = "var.img";
                      size = 256;
                    }
                  ];
                  shares = [
                    {
                      # use proto = "virtiofs" for MicroVMs that are started by systemd
                      proto = "9p";
                      tag = "ro-store";
                      # a host's /nix/store will be picked up so that no
                      # squashfs/erofs will be built for it.
                      source = "/nix/store";
                      mountPoint = "/nix/.ro-store";
                    }
                  ];

                  # "qemu" has 9p built-in!
                  hypervisor = "qemu";
                  socket = "control.socket";
                };
              }
            ];
          }
        )
      );
    };

  };
}
