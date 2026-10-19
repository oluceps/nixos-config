{ nixpkgs }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  inherit (pkgs) lib;
  secret = pkgs.writeText "dummy-immich.env" "DB_PASSWORD=dummy\n";
  fixture = pkgs.writeText "immich-fixture.py" ''
    import http.server
    import json
    import os
    import pwd
    import socket
    import subprocess
    import sys
    import urllib.request

    mode = sys.argv[1]

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            try:
                if mode == "ml":
                    result = pwd.getpwuid(os.getuid()).pw_name.encode()
                elif mode == "proxy":
                    with urllib.request.urlopen(os.environ["IMMICH_URL"] + self.path, timeout=10) as response:
                        result = response.read()
                else:
                    database = subprocess.check_output([
                        "psql", os.environ["DB_URL"], "-Atc",
                        "select current_user, current_database()",
                    ], text=True, timeout=10).strip()
                    with socket.create_connection(("127.0.0.1", 6379), timeout=10) as redis:
                        redis.sendall(b"*1\r\n$4\r\nPING\r\n")
                        pong = redis.recv(1024).decode().strip()
                    with urllib.request.urlopen("http://127.0.0.1:3003/", timeout=10) as response:
                        ml = response.read().decode()
                    result = json.dumps({"database": database, "redis": pong, "ml": ml}).encode()
            except Exception:
                self.send_error(503, "dependency unavailable")
                return
            self.send_response(200)
            self.end_headers()
            self.wfile.write(result)

    port = int(os.environ["IPP_PORT"] if mode == "proxy" else os.environ["IMMICH_PORT"])
    http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
  '';
  executable =
    mode:
    pkgs.writeShellScriptBin "immich-${mode}-fixture" ''
      exec ${pkgs.python3}/bin/python3 ${fixture} ${mode}
    '';
in
pkgs.testers.runNixOSTest {
  name = "realm-immich";
  nodes.machine =
    { config, ... }:
    {
      imports = [
        ../nixosModules/realm-workloads.nix
        ../nixosModules/realm-spire.nix
        ../nixosModules/service-discovery.nix
        (import ../mod/immich.nix).flake.modules.nixos.immich
        (import ../mod/postgresql.nix).flake.modules.nixos.postgresql
        (import ../mod/realm-internet.nix).flake.modules.nixos.realm-internet
        {
          options.vaultix.secrets = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = { };
          };
          config.vaultix.secrets.immich.path = toString secret;
        }
      ];
      networking.hostName = "machine";
      virtualisation.memorySize = 2048;
      environment.systemPackages = [
        pkgs.curl
        pkgs.util-linux
      ];
      services.immich.package = (executable "server") // {
        machine-learning = executable "ml";
      };
      services.immich-public-proxy.package = executable "proxy";
      services.prometheus.exporters.postgres.enable = lib.mkForce false;
      services.postgresql = {
        ensureDatabases = [ "immich" ];
        ensureUsers = [
          {
            name = "immich";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              password = "dummy";
            };
          }
        ];
        settings = {
          shared_buffers = lib.mkForce "32MB";
          effective_cache_size = lib.mkForce "128MB";
          maintenance_work_mem = lib.mkForce "32MB";
          work_mem = lib.mkForce "4MB";
          huge_pages = lib.mkForce "off";
        };
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
            registrations.machine = lib.mapAttrs (
              _: entry:
              entry
              // {
                parentID = "spiffe://nyaw.xyz/agent/machine";
              }
            ) config.realm.spire.registrations;
          };
        };
        workloads = {
          caddy.egress = {
            immich = {
              service = "immich";
              verifyID = "spiffe://nyaw.xyz/service/immich";
              localPort = 12283;
            };
            public-proxy = {
              service = "immich-public-proxy";
              verifyID = "spiffe://nyaw.xyz/service/immich-public-proxy";
              localPort = 13001;
            };
          };
          imposter.egress = {
            immich = {
              service = "immich";
              verifyID = "spiffe://nyaw.xyz/service/immich";
              localPort = 12283;
            };
            postgresql = {
              service = "postgresql-immich";
              verifyID = "spiffe://nyaw.xyz/service/postgresql";
              localPort = 15432;
            };
            internet = {
              service = "internet-proxy";
              verifyID = "spiffe://nyaw.xyz/service/internet";
              localPort = 13128;
            };
          };
        };
      };
      systemd.services =
        lib.genAttrs [ "caddy" "imposter" ] (name: {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = name;
            Group = name;
            ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
          };
        })
        // {
          postgresql.serviceConfig.ReadWritePaths = lib.mkForce [ ];
        };
    };
  testScript = ''
    import json

    def inside(unit, command):
        return f"nsenter -t $(systemctl show -p MainPID --value {unit}.service) -n {command}"

    machine.start()
    machine.wait_for_unit("spire-server.service")
    machine.wait_for_unit("realm-spire-register.service")
    machine.succeed("realm-enroll machine | realm-install-enrollment")
    machine.wait_for_unit("spire-agent.service")
    for unit in ["postgresql", "redis-immich", "immich-server", "immich-machine-learning", "immich-public-proxy", "caddy", "imposter"]:
        machine.wait_for_unit(f"{unit}.service")

    with subtest("authorized application dependencies and public proxy chain"):
        request = inside("caddy", "curl -fsS --max-time 20 http://127.0.0.1:13001/")
        machine.wait_until_succeeds(request, timeout=120)
        result = json.loads(machine.succeed(request))
        assert result == {"database": "immich|immich", "redis": "+PONG", "ml": "immich-ml"}, result
        machine.succeed(inside("caddy", "curl -fsS --max-time 20 http://127.0.0.1:12283/"))

    with subtest("dedicated PostgreSQL peer identity cannot become another database role"):
        machine.succeed("runuser -u realm-pg-immich -- psql -h /run/postgresql -U immich -d immich -Atc 'select current_user' | grep -x immich")
        machine.fail("runuser -u realm-pg-atuin -- psql -h /run/postgresql -U immich -d immich -Atc 'select current_user'")

    with subtest("mesh TCP password authentication is disabled"):
        machine.succeed("ip -6 address add fdcc::3/128 dev lo")
        machine.fail("PGPASSWORD=dummy psql -h fdcc::3 -U immich -d immich -Atc 'select current_user'")
        machine.fail(inside("immich-server", "timeout 5 psql -h fdcc::3 -U immich -d immich -Atc 'select current_user'"))

    with subtest("unauthorized SPIFFE client is rejected by both receivers"):
        machine.succeed("systemctl start realm-egress-imposter-immich.service realm-egress-imposter-postgresql.service realm-egress-imposter-internet.service")
        machine.wait_for_unit("realm-egress-imposter-immich.service")
        machine.wait_for_unit("realm-egress-imposter-postgresql.service")
        machine.fail(inside("imposter", "curl -fsS --max-time 5 http://127.0.0.1:12283/"))
        machine.fail(inside("imposter", "timeout 5 psql 'postgresql://immich@127.0.0.1:15432/immich?sslmode=disable' -Atc 'select current_user'"))

    with subtest("only ML identity may use its Internet proxy"):
        machine.succeed("ip address add 198.51.100.1/32 dev lo")
        machine.succeed("systemd-run --unit=public-fixture ${pkgs.python3}/bin/python3 -m http.server 80 --bind 198.51.100.1 --directory /etc")
        request = "curl --noproxy \"\" -fsS --max-time 10 --proxy http://127.0.0.1:13128 http://198.51.100.1/hostname"
        machine.wait_until_succeeds(inside("immich-machine-learning", request), timeout=30)
        machine.wait_for_unit("realm-egress-imposter-internet.service")
        machine.fail(inside("imposter", request))

    with subtest("private listeners and runtime sockets do not bypass the mesh"):
        for port in [2283, 3003, 3001]:
            machine.fail(f"curl -fsS --max-time 2 http://127.0.0.1:{port}/")
        pid = machine.succeed("systemctl show -p MainPID --value immich-server.service").strip()
        for path in ["/run/spire/agent/public/api.sock", "/run/postgresql/.s.PGSQL.5432", "/run/redis-immich/redis.sock"]:
            machine.succeed(f"nsenter -t {pid} -m ${pkgs.coreutils}/bin/test ! -e {path}")
        machine.fail(inside("immich-server", "curl --noproxy '*' -fsS --max-time 2 http://198.51.100.1/hostname"))
  '';
}
