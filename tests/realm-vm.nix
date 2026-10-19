{ nixpkgs }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
pkgs.testers.runNixOSTest {
  name = "realm-workload-networking";
  nodes.machine =
    { config, ... }:
    {
      imports = [
        ../nixosModules/realm-workloads.nix
        ../nixosModules/realm-spire.nix
        ../nixosModules/service-discovery.nix
        (import ../mod/realm-internet.nix).flake.modules.nixos.realm-internet
      ];
      virtualisation.memorySize = 2048;
      networking.hostName = "machine";
      environment.systemPackages = [
        pkgs.curl
        pkgs.util-linux
        pkgs.postgresql
      ];
      services.postgresql = {
        enable = true;
        authentication = pkgs.lib.mkForce "local sender sender peer map=realm\nlocal all all peer";
        identMap = "realm realm-pg-sender sender";
        ensureDatabases = [ "sender" ];
        ensureUsers = [
          {
            name = "sender";
            ensureDBOwnership = true;
          }
        ];
      };
      services.consul.extraConfig = {
        server = true;
        bootstrap_expect = 1;
        bind_addr = "127.0.0.1";
        advertise_addr = "127.0.0.1";
        client_addr = "127.0.0.1";
        domain = "mesh.nyaw.xyz";
        dns_config.only_passing = true;
      };
      realm = {
        enable = true;
        serviceDiscovery = {
          enable = true;
          address = "::1";
        };
        spire = {
          serverAddress = "::1";
          server = {
            enable = true;
            registrations.machine = pkgs.lib.mapAttrs (
              _: entry:
              entry
              // {
                parentID = "spiffe://nyaw.xyz/agent/machine";
              }
            ) config.realm.spire.registrations;
          };
        };
        workloads = {
          internet.ingress.http.allowedIDs = pkgs.lib.mkForce [ "spiffe://nyaw.xyz/service/sender" ];
          native = {
            isolation.privateNetwork = false;
            credentials.enable = true;
          };
          sender.egress = {
            internet = {
              service = "internet-proxy";
              verifyID = "spiffe://nyaw.xyz/service/internet";
              localPort = 13128;
            };
            receiver = {
              service = "receiver";
              verifyID = "spiffe://nyaw.xyz/service/receiver";
              localPort = 13100;
            };
            postgresql = {
              service = "postgresql-sender";
              verifyID = "spiffe://nyaw.xyz/service/postgresql";
              localPort = 15432;
            };
          };
          postgresql = {
            user = "postgres";
            group = "postgres";
            isolation.runtimePaths = [ "/run/postgresql" ];
            ingress.sender = {
              port = 19432;
              target = "unix:/run/postgresql/.s.PGSQL.5432";
              consulService = "postgresql-sender";
              backendUser = "realm-pg-sender";
              allowedIDs = [ "spiffe://nyaw.xyz/service/sender" ];
            };
          };
          imposter.egress.receiver = {
            service = "receiver";
            verifyID = "spiffe://nyaw.xyz/service/receiver";
            localPort = 13100;
          };
          wrong-server.egress.receiver = {
            service = "receiver";
            verifyID = "spiffe://nyaw.xyz/service/not-receiver";
            localPort = 13100;
          };
          receiver.ingress.http = {
            port = 19429;
            target = "127.0.0.1:3030";
            privateLoopback = true;
            consulService = "receiver";
            allowedIDs = [
              "spiffe://nyaw.xyz/service/sender"
              "spiffe://nyaw.xyz/service/wrong-server"
            ];
          };
        };
      };
      users.groups = {
        sender = { };
        receiver = { };
        imposter = { };
        wrong-server = { };
        native = { };
        realm-pg = { };
      };
      users.users =
        pkgs.lib.genAttrs [ "sender" "receiver" "imposter" "wrong-server" "native" ] (name: {
          isSystemUser = true;
          group = name;
        })
        // {
          realm-pg-sender = {
            isSystemUser = true;
            group = "realm-pg";
          };
        };
      systemd.services =
        (pkgs.lib.genAttrs [ "sender" "imposter" "wrong-server" "native" ] (name: {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = name;
            Group = name;
            ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
          };
        }))
        // {
          receiver = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "receiver";
              Group = "receiver";
              ExecStart = "${pkgs.python3}/bin/python3 -m http.server 3030 --bind 127.0.0.1";
              WorkingDirectory = "/etc";
            };
          };
        };
    };
  testScript = ''
    machine.start()
    machine.wait_for_unit("spire-server.service")
    machine.wait_for_unit("realm-spire-register.service")
    machine.succeed("realm-enroll machine | realm-install-enrollment")
    machine.wait_for_unit("spire-agent.service")
    machine.wait_for_unit("receiver.service")
    machine.wait_until_succeeds("curl -sf 'http://127.0.0.1:8500/v1/health/service/receiver?passing' | grep -q 19429")

    def probe(name):
        return f"nsenter -t $(systemctl show -p MainPID --value {name}.service) -n curl -fsS --max-time 10 http://127.0.0.1:13100/hostname"

    with subtest("SRV discovery and authorized mTLS"):
        machine.wait_until_succeeds(probe("sender"), timeout=90)
    with subtest("unauthorized client identity"):
        machine.fail(probe("imposter"))
    with subtest("wrong server identity"):
        machine.fail(probe("wrong-server"))
    with subtest("PostgreSQL peer authentication survives the tunnel"):
        machine.wait_until_succeeds("nsenter -t $(systemctl show -p MainPID --value sender.service) -n psql postgresql://sender@127.0.0.1:15432/sender -Atc 'select current_user' | grep -x sender", timeout=30)
    with subtest("authenticated Internet proxy permits public destinations"):
        machine.succeed("ip address add 198.51.100.1/32 dev lo")
        machine.succeed("systemd-run --unit=public-fixture ${pkgs.python3}/bin/python3 -m http.server 80 --bind 198.51.100.1 --directory /etc")
        machine.wait_until_succeeds("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" -fsS --max-time 10 --proxy http://127.0.0.1:13128 http://198.51.100.1/hostname", timeout=30)
    with subtest("Internet proxy denies private and Yggdrasil destinations"):
        for destination in ["127.0.0.1", "[fdcc::3]", "[200::1]"]:
            result = machine.succeed(f"nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" -sS -o /dev/null -w '%{{http_code}}' --max-time 10 --proxy http://127.0.0.1:13128 http://{destination}/")
            assert result == "403", (destination, result)
    with subtest("raw backend is private"):
        machine.fail("curl -sf --max-time 2 http://127.0.0.1:3030/hostname")
    with subtest("host sockets are hidden from workload"):
        machine.succeed("nsenter -t $(systemctl show -p MainPID --value sender.service) -m ${pkgs.coreutils}/bin/test ! -e /run/spire/agent/public/api.sock")
        machine.succeed("nsenter -t $(systemctl show -p MainPID --value sender.service) -m ${pkgs.coreutils}/bin/test ! -e /run/realm/imposter/egress/receiver.sock")
    with subtest("native consumer can read helper credentials"):
        machine.wait_for_unit("realm-helper-native.service")
        machine.succeed("runuser -u native -- test -r /run/realm/native/credentials/key.pem")
        machine.succeed("nsenter -t $(systemctl show -p MainPID --value native.service) -m ${pkgs.coreutils}/bin/test -s /run/realm/native/credentials/svid.pem")
    with subtest("workload cannot connect directly to ingress"):
        machine.fail("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl -skf --max-time 2 https://[::1]:19429/")
    with subtest("idempotent registration synchronization"):
        machine.succeed("systemctl restart realm-spire-register.service")
        machine.succeed(probe("sender"))
  '';
}
