{
  description = "Standalone bootstrap flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      ...
    }@inputs:
    {
      nixosConfigurations.bootstrap = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko

          (
            { lib, pkgs, ... }:
            {
              time.timeZone = "Asia/Hong_Kong";
              networking = {
                nameservers = [ "8.8.8.8" ];
                usePredictableInterfaceNames = false;
                firewall.enable = false;
                useNetworkd = true;
                hostName = "bootstrap";
              };
              boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

              users.mutableUsers = false;
              users.users.root = {
                # Password is 'nixos'
                # use `mkpasswd`
                initialHashedPassword = "$y$j9T$3PwI66LqThCofyKAWWHeA0$owp2WjGg3grbz4YisFnxfIfMmhHcxiFxDSsiTqv8xh5";
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlk4fFt1HfVenQFTyGgxHfxqPB8spVtZqzBC5R2gYNg ed-login-250928"
                ];
              };

              systemd.network.enable = true;
              services.resolved.enable = true;

              services.openssh = {
                enable = true;
                ports = [ 22 ];
                settings = {
                  PasswordAuthentication = false;
                  PermitRootLogin = lib.mkForce "prohibit-password";
                };
              };

              boot = {
                loader.limine = {
                  enable = true;
                  efiSupport = true;
                  biosSupport = true;
                  biosDevice = "/dev/sda";
                };
                kernelParams = [
                  "audit=0"
                  "net.ifnames=0"
                  "rootdelay=300"
                  "19200n8"
                ];
                initrd = {
                  compressor = "zstd";
                  compressorArgs = [
                    "-19"
                    "-T0"
                  ];
                  systemd.enable = true;
                };
              };

              fileSystems."/persist".neededForBoot = true;
              disko.devices = {
                disk.main = {
                  imageSize = "2G";
                  type = "disk";
                  device = "/dev/sda";
                  content = {
                    type = "gpt";
                    partitions = {
                      boot = {
                        size = "1M";
                        priority = 0;
                        type = "EF02";
                      };
                      ESP = {
                        name = "ESP";
                        size = "256M";
                        type = "EF00";
                        content = {
                          type = "filesystem";
                          format = "vfat";
                          mountpoint = "/boot";
                          mountOptions = [ "umask=0077" ];
                        };
                      };
                      solid = {
                        label = "SOLID";
                        end = "-0";
                        content = {
                          type = "btrfs";
                          extraArgs = [
                            "--label nixos"
                            "-f"
                            "--csum xxhash64"
                            "--features"
                            "block-group-tree"
                          ];
                          subvolumes = {
                            "root" = {
                              mountpoint = "/";
                              mountOptions = [
                                "compress=zstd"
                                "noatime"
                                "nodev"
                                "nosuid"
                              ];
                            };
                            "nix" = {
                              mountpoint = "/nix";
                              mountOptions = [
                                "compress=zstd"
                                "noatime"
                                "nodev"
                                "nosuid"
                              ];
                            };
                            "var" = {
                              mountpoint = "/var";
                              mountOptions = [
                                "compress=zstd"
                                "noatime"
                                "nodev"
                                "nosuid"
                              ];
                            };
                            "persist" = {
                              mountpoint = "/persist";
                              mountOptions = [
                                "compress=zstd"
                                "noatime"
                              ];
                            };
                          };
                        };
                      };
                    };
                  };
                };
              };

              systemd.network.links."10-eno1" = {
                matchConfig.MACAddress = "bc:24:11:88:90:da";
                linkConfig.Name = "eno1";
              };
              systemd.network.networks."8-eno1" = {
                matchConfig.Name = "eno1";
                networkConfig = {
                  DHCP = "no";
                  IPv4Forwarding = true;
                  IPv6Forwarding = true;
                  IPv6AcceptRA = true;
                  MulticastDNS = true;
                };
                ipv6AcceptRAConfig = {
                  DHCPv6Client = false;
                  # UseDNS = false;
                };
                domains = [ "PVE" ];

                address = [
                  "2401:b60:e0fe:15::2/64"
                ];
                linkConfig.RequiredForOnline = "routable";
                routes = [
                  {
                    Gateway = "2401:b60:e0fe:15::1";
                    # GatewayOnLink = true;
                  }
                ];
              };

              nixpkgs.hostPlatform = "x86_64-linux";
              system.stateVersion = "25.11";
            }
          )
        ];
      };
    };
}
