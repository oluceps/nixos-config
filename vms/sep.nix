{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.microvm.nixosModules.host
  ];
  microvm.autostart = [
    "sep-microvm"
  ];
  microvm.vms = {
    sep-microvm =
      let
        index = 1;
        mac = "00:00:00:00:00:01";
      in
      {
        inherit pkgs;
        restartIfChanged = true;
        #specialArgs = {};

        config = {
          imports = [ ../modules/hysteria.nix ];
          networking.hostName = "sep-microvm";
          networking.useNetworkd = true;

          # forbid access to RFC1918 addr scope & IPv6
          networking.firewall.enable = true;
          networking.nftables.enable = true;
          networking.nftables.ruleset = ''
            table inet filter {
              chain input {
                type filter hook input priority filter;
                policy drop;

                ct state established,related accept

                iifname "lo" accept

                ip saddr 10.255.0.0 tcp dport 22 accept
                # tcp dport 22 accept
              }
              chain output {
                type filter hook output priority filter;
                policy accept;

                iifname "lo" accept
                ct state established,related accept

                ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } reject with icmp type admin-prohibited
                ip6 daddr fc00::/7 reject with icmpv6 type admin-prohibited
              }
            }
          '';
          networking.enableIPv6 = false;
          # forbid end

          services.openssh.hostKeys = [
            {
              path = "/var/lib/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
          systemd.network = {

            netdevs.wg-ext = {
              netdevConfig = {
                Kind = "wireguard";
                Name = "wg-ext";
              };
              wireguardConfig = {
                PrivateKeyFile = "/var/lib/wg-ext/key";
              };
              wireguardPeers = [
                {
                  PublicKey = "2pmaKNynwrVEvOcUXuFfYDGRp5UKbK89DmOSCnjklRk=";
                  Endpoint = "127.0.0.1:51700";
                  PersistentKeepalive = 15;
                  AllowedIPs = [
                    "10.10.10.2/32"
                  ];
                }
              ];
            };
            networks."90-wg-ext" = {
              matchConfig.Name = "wg-ext";
              address = [ "10.10.10.1/24" ];
              DHCP = "no";
            };

            networks."10-eth" = {
              matchConfig.MACAddress = mac;
              # Static IP configuration
              address = [
                "10.255.0.${toString index}/32"
                "fec0::${lib.toHexString index}/128"
              ];
              routes = [
                {
                  # route to the host
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
                  "223.6.6.6"
                  "8.8.8.8"
                ];
              };
            };
          };
          users.users.root = {
            initialHashedPassword = "$2b$05$y36LF2A5ybA9oA0LuJnZMu4BjBJvPn.CpjEbdQRDSZn8z4N7RYm9W";
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG"
            ];
          };
          # attack test
          environment.systemPackages = [
            pkgs.wireguard-tools
            pkgs.nmap
            pkgs.metasploit
            pkgs.mtr
            pkgs.traceroute
            pkgs.nftables

          ];
          services.hysteria.instances = {
            ext = {
              enable = true;
              configFile = "/var/lib/hy/config.yml";
            };
          };
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
              UseDns = false;
              X11Forwarding = false;
              KexAlgorithms = [
                # pqc
                "mlkem768x25519-sha256"
                "sntrup761x25519-sha512"
                "sntrup761x25519-sha512@openssh.com"
              ];
            };
            authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
            extraConfig = ''
              ClientAliveInterval 60
              ClientAliveCountMax 720
            '';
          };
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
        };
      };
  };
}
