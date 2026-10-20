{ nixpkgs }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    overlays = [ ];
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
        ../nixosModules/realm-observability.nix
        ../nixosModules/service-discovery.nix
        (import ../mod/realm-internet.nix).flake.modules.nixos.realm-internet
      ];
      virtualisation.memorySize = 2048;
      networking.hostName = "machine";
      environment.systemPackages = [
        pkgs.curl
        pkgs.util-linux
        pkgs.postgresql
        pkgs.openssl
        pkgs.dnsutils
      ];
      realm.observability = {
        enable = true;
        endpoints = {
          fixture = {
            port = 18081;
            publicProxyPort = 18082;
          };
          business = {
            port = 18081;
            businessProxyPort = 18084;
            businessAllowedIDs = [ "spiffe://nyaw.xyz/service/sender" ];
          };
          prober = {
            port = 18083;
            kind = "probe";
            path = "/probe";
            probes = [
              {
                module = "icmp";
                target = "198.51.100.1";
              }
              # A URL target is percent-encoded in the query, which the gateway
              # must accept: only the path is subject to the slash checks.
              {
                module = "http_2xx";
                target = "https://example.invalid";
              }
            ];
          };
        };
      };
      services.dnsmasq = {
        enable = true;
        settings = {
          listen-address = "127.0.0.1";
          bind-interfaces = true;
          no-resolv = true;
          address = [
            "/public.test/198.51.100.1"
            "/public-v6.test/2001:db8::1"
            "/private.test/127.0.0.1"
            "/mesh.test/fdcc::3"
            "/ygg.test/200::1"
          ];
        };
      };
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
          vmagent.egress.observation = {
            service = "observability-machine";
            verifyID = "spiffe://nyaw.xyz/service/observability-machine";
            localPort = 13190;
          };
          sender.socksProxy.enable = true;
          synapse.egress.internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/internet";
            localPort = 13128;
          };
          sender.egress.observation = {
            service = "observability-machine";
            verifyID = "spiffe://nyaw.xyz/service/observability-machine";
            localPort = 13190;
          };
          sender.egress.business = {
            service = "business-machine";
            verifyID = "spiffe://nyaw.xyz/service/observability-machine";
            localPort = 13191;
          };
          internet.ingress.http.allowedIDs = pkgs.lib.mkForce [
            "spiffe://nyaw.xyz/service/sender"
            "spiffe://nyaw.xyz/service/synapse"
          ];
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
              service = "postgresql-sender";
              backendUser = "realm-pg-sender";
              allowedIDs = [ "spiffe://nyaw.xyz/service/sender" ];
            };
          };
          imposter.egress.receiver = {
            service = "receiver";
            verifyID = "spiffe://nyaw.xyz/service/receiver";
            localPort = 13100;
          };
          imposter.egress.business = {
            service = "business-machine";
            verifyID = "spiffe://nyaw.xyz/service/observability-machine";
            localPort = 13192;
          };
          imposter.egress.internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/internet";
            localPort = 13128;
          };
          wrong-server.egress.receiver = {
            service = "receiver";
            verifyID = "spiffe://nyaw.xyz/service/not-receiver";
            localPort = 13100;
          };
          wrong-server.egress.internet = {
            service = "internet-proxy";
            verifyID = "spiffe://nyaw.xyz/service/not-internet";
            localPort = 13128;
          };
          receiver.ingress.http = {
            port = 19429;
            target = "127.0.0.1:3030";
            privateLoopback = true;
            service = "receiver";
            allowedIDs = [
              "spiffe://nyaw.xyz/service/sender"
              "spiffe://nyaw.xyz/service/wrong-server"
            ];
          };
        };
      };
      users.groups = {
        sender = { };
        synapse = { };
        receiver = { };
        imposter = { };
        wrong-server = { };
        native = { };
        vmagent = { };
        realm-pg = { };
      };
      users.users =
        pkgs.lib.genAttrs
          [
            "synapse"
            "sender"
            "receiver"
            "imposter"
            "wrong-server"
            "native"
            "vmagent"
          ]
          (name: {
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
        (pkgs.lib.genAttrs [ "synapse" "sender" "imposter" "wrong-server" "native" "vmagent" ] (name: {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = name;
            Group = name;
            ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
          };
        }))
        // {
          observation-fixture = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${pkgs.writeText "observation-fixture.py" ''
              import http.server, threading
              class Handler(http.server.BaseHTTPRequestHandler):
                  def do_GET(self):
                      self.send_response(200)
                      self.end_headers()
                      self.wfile.write(("fixture_metric 1\\n" + self.path).encode())
              for port in [18081, 18083]:
                  server = http.server.HTTPServer(("0.0.0.0", port), Handler)
                  threading.Thread(target=server.serve_forever, daemon=True).start()
              threading.Event().wait()
            ''}";
          };
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
    machine.wait_for_unit("coredns.service")
    machine.succeed("dig @127.0.0.1 -p 8600 +short SRV receiver.svc.mesh.nyaw.xyz | grep -q '19429 receiver.machine.svc.mesh.nyaw.xyz.'")

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
        machine.succeed("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" -fsS --max-time 10 --proxy http://127.0.0.1:13128 http://public.test/hostname")
    with subtest("Internet proxy requires an authorized SPIFFE client and the expected server identity"):
        for name in ["imposter", "wrong-server"]:
            machine.fail(f"nsenter -t $(systemctl show -p MainPID --value {name}.service) -n curl --noproxy \"\" -fsS --max-time 5 --proxy http://127.0.0.1:13128 http://198.51.100.1/hostname")
        machine.fail("curl --noproxy '*' -skf --max-time 3 https://[::1]:19328/")
    with subtest("CONNECT passes application TLS unchanged"):
        machine.succeed("openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/public.key -out /tmp/public.crt -days 1 -subj /CN=public.test -addext subjectAltName=DNS:public.test")
        machine.succeed("cp /tmp/public.crt /etc/public-fixture.crt")
        machine.succeed("systemd-run --unit=tls-fixture ${pkgs.python3}/bin/python3 -c 'import http.server,ssl; s=http.server.HTTPServer((\"198.51.100.1\",443),http.server.SimpleHTTPRequestHandler); c=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); c.load_cert_chain(\"/tmp/public.crt\",\"/tmp/public.key\"); s.socket=c.wrap_socket(s.socket,server_side=True); s.serve_forever()' --directory /etc")
        machine.wait_until_succeeds("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" --cacert /etc/public-fixture.crt -fsS --max-time 10 --proxy http://127.0.0.1:13128 https://public.test/", timeout=30)
    with subtest("SOCKS clients traverse the authenticated HTTP gateway"):
        machine.wait_until_succeeds("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" --cacert /etc/public-fixture.crt -fsS --max-time 10 --socks5-hostname 127.0.0.1:11080 https://public.test/", timeout=30)
        machine.fail("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" -ksf --max-time 5 --socks5-hostname 127.0.0.1:11080 https://private.test/")
    with subtest("only Synapse may use federation port 8448"):
        machine.succeed("systemd-run --unit=federation-fixture ${pkgs.python3}/bin/python3 -m http.server 8448 --bind 198.51.100.1")
        machine.wait_until_succeeds("nsenter -t $(systemctl show -p MainPID --value synapse.service) -n curl --noproxy \"\" --proxytunnel -fsS --max-time 10 --proxy http://127.0.0.1:13128 http://public.test:8448/", timeout=30)
        machine.fail("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" --proxytunnel -fsS --max-time 5 --proxy http://127.0.0.1:13128 http://public.test:8448/")
    with subtest("public IPv6 destination"):
        machine.succeed("ip -6 address add 2001:db8::1/128 dev lo")
        machine.succeed("systemd-run --unit=public-v6-fixture ${pkgs.python3}/bin/python3 -m http.server 80 --bind 2001:db8::1 --directory /etc")
        machine.wait_until_succeeds("nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" -fsS --max-time 10 --proxy http://127.0.0.1:13128 http://public-v6.test/hostname", timeout=30)
    with subtest("Internet proxy denies private and Yggdrasil destinations"):
        for destination in ["127.0.0.1", "[fdcc::3]", "[200::1]", "[::ffff:127.0.0.1]", "private.test", "mesh.test", "ygg.test"]:
            result = machine.succeed(f"nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" -sS -o /dev/null -w '%{{http_code}}' --max-time 10 --proxy http://127.0.0.1:13128 http://{destination}/")
            assert result == "403", (destination, result)
    with subtest("CONNECT destination and port restrictions"):
        for destination in ["private.test:443", "[fdcc::3]:443", "[200::1]:443", "public.test:80", "public.test:8443"]:
            result = machine.succeed(f"nsenter -t $(systemctl show -p MainPID --value sender.service) -n curl --noproxy \"\" --proxytunnel -sS -o /dev/null -w '%{{http_connect}}' --max-time 10 --proxy http://127.0.0.1:13128 http://{destination}/ || true")
            assert result.strip() == "403", (destination, result)
    with subtest("native ingress replaces the gateway ghostunnel"):
        machine.fail("systemctl cat realm-ingress-internet-http.service")
        machine.fail("ss -lnt | grep -E '127.0.0.1:3128\\b'")
    def observe(path, flags="", name="vmagent"):
        return f"nsenter -t $(systemctl show -p MainPID --value {name}.service) -n curl --path-as-is -sS --max-time 5 {flags} 'http://127.0.0.1:13190{path}'"

    with subtest("only the observation identity can read metrics"):
        machine.wait_until_succeeds(observe("/fixture/metrics", "-f"), timeout=30)
        machine.fail(observe("/fixture/metrics", "-f", "sender"))
        machine.succeed(observe("/fixture/metrics", "-f") + " | grep -F /metrics")
    with subtest("observation ingress cannot access business or debugging endpoints"):
        for path in ["/", "/debug/pprof", "/fixture/metrics?debug=1", "/fixture/../debug/pprof", "/fixture/%2fdebug/pprof"]:
            result = machine.succeed(observe(path, "-o /dev/null -w '%{http_code}'"))
            assert result in ["400", "403", "404"], (path, result)
        assert machine.succeed(observe("/fixture/metrics", "-X POST -o /dev/null -w '%{http_code}'")) == "403"
    with subtest("probe requires an exact module and target without duplicate or extra parameters"):
        machine.succeed(observe("/prober/probe?module=icmp&target=198.51.100.1", "-f"))
        machine.succeed(observe("/prober/probe?target=198.51.100.1&module=icmp", "-f"))
        machine.succeed(observe("/prober/probe?module=http_2xx&target=https%3A%2F%2Fexample.invalid", "-f"))
        for query in ["module=icmp&target=127.0.0.1", "module=unknown&target=198.51.100.1", "module=icmp&target=198.51.100.1&target=127.0.0.1", "module=icmp&target=198.51.100.1&%74arget=127.0.0.1", "module=icmp&target=198.51.100.1&debug=true", "module=icmp&target=198.51.100.1&module=http_2xx"]:
            assert machine.succeed(observe("/prober/probe?" + query, "-o /dev/null -w '%{http_code}'")) == "403", query
    with subtest("the plaintext business port keeps its path restrictions"):
        machine.succeed("curl --noproxy '*' -gf --max-time 5 http://[::1]:18082/index")
        for path in ["/metrics", "/metrics?debug=1", "/metrics/", "/%6detrics", "//metrics", "/debug/pprof"]:
            assert machine.succeed(f"curl --noproxy '*' -gsS --max-time 5 -o /dev/null -w '%{{http_code}}' 'http://[::1]:18082{path}'") == "403", path
    def business(path, flags="", name="sender", port=13191):
        return f"nsenter -t $(systemctl show -p MainPID --value {name}.service) -n curl --path-as-is -sS --max-time 5 {flags} 'http://127.0.0.1:{port}{path}'"

    with subtest("the authenticated business API excludes observation and debugging endpoints"):
        machine.wait_until_succeeds(business("/index", "-f"), timeout=90)
        machine.succeed(business("/index", "-f") + " | grep -F /index")
        machine.succeed(business("/api/v1/query?query=up", "-f"))
        for path in ["/metrics", "/metrics/extra", "/debug/pprof", "/metrics?format=prometheus", "/a/../metrics", "//metrics"]:
            assert machine.succeed(business(path, "--path-as-is -o /dev/null -w '%{http_code}'")) == "403"
        assert machine.succeed(business("/metrics%2fextra", "--path-as-is -o /dev/null -w '%{http_code}'")) == "400"
        assert machine.succeed(business("/index", "-X POST -o /dev/null -w '%{http_code}'")) in ["200", "405", "501"]
    with subtest("the authenticated API listener rejects unauthorized identities"):
        machine.fail(business("/index", "-f", "imposter", 13192))
        machine.fail("curl --noproxy '*' -skf --max-time 3 https://[::1]:18084/")
    with subtest("raw backend ports remain blocked if a backend binds all interfaces"):
        machine.succeed("ip netns add observation-untrusted")
        machine.succeed("ip link add obs-host type veth peer name obs-client")
        machine.succeed("ip link set obs-client netns observation-untrusted")
        machine.succeed("ip addr add 192.0.2.1/30 dev obs-host && ip link set obs-host up")
        machine.succeed("ip -n observation-untrusted addr add 192.0.2.2/30 dev obs-client && ip -n observation-untrusted link set obs-client up")
        machine.fail("ip netns exec observation-untrusted curl -sf --max-time 2 http://192.0.2.1:18083/probe")
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
