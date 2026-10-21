{ nixpkgs }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  inherit (pkgs) lib;
  backend = pkgs.writeText "fixture.cjs" ''
    const fs = require('node:fs');
    const http = require('node:http');
    const net = require('node:net');
    const socket = '/realm/backend/http.sock';
    if (!process.env.REALM_INGRESS_PORT) fs.rmSync(socket, { force: true });
    http.createServer((req, res) => {
      const client = net.createConnection(process.env.REALM_INGRESS_PORT ? 15432 : 5432, '127.0.0.1', () => client.write('mesh'));
      client.on('data', (data) => { res.end(process.getuid()+':'+process.getgid()+':'+data); client.end(); });
      client.on('error', () => { res.statusCode = 503; res.end('unreachable'); });
    }).listen(process.env.REALM_INGRESS_PORT ? 3333 : socket, () => {
      if (!process.env.REALM_INGRESS_PORT) fs.chmodSync(socket, 0o660);
    });
    if (process.env.REALM_INGRESS_PORT) http.createServer((req, res) => res.end('healthy')).listen(3000, '127.0.0.1');
  '';
  pnpm = pkgs.writeShellScriptBin "pnpm" "exec ${pkgs.nodejs}/bin/node ${backend}";
  image = pkgs.dockerTools.buildLayeredImage {
    name = "realm-container-fixture";
    tag = "test";
    contents = [
      pkgs.nodejs
      pkgs.coreutils
      pkgs.bash
      pnpm
    ];
    config.Env = [ "PATH=/bin" ];
  };
  source = pkgs.writeText "dummy-misskey.yml" ''
    url: https://example.invalid/
    socket: /realm/backend/http.sock
    chmodSocket: '660'
    db: { db: fixture, user: fixture, pass: dummy, host: 127.0.0.1, port: 5432 }
    redis: { host: 127.0.0.1, port: 6379 }
    meilisearch: { apiKey: dummy, host: 127.0.0.1, port: 7700 }
    proxy: http://127.0.0.1:13128
    proxyBypassHosts: [s3.nyaw.xyz]
    allowedPrivateNetworks: [127.0.0.0/8]
  '';
  echo = pkgs.writeText "echo-activation.py" ''
    import socket
    listener = socket.socket(fileno=3)
    while True:
        client, _ = listener.accept()
        with client:
            client.sendall(client.recv(65536))
  '';
in
pkgs.testers.runNixOSTest {
  name = "realm-rootless-container";
  nodes.machine = {
    imports = [
      ../nixosModules/realm-workloads.nix
      ../nixosModules/realm-spire.nix
      ../nixosModules/service-discovery.nix
      (import ../mod/realm-caddy-policy.nix).flake.modules.nixos.realm
      (import ../mod/misskey.nix).flake.modules.nixos.misskey
      (import ../mod/telegram-search.nix).flake.modules.nixos.telegram-search
      (
        { ... }:
        {
          options.vaultix.secrets = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  path = lib.mkOption {
                    type = lib.types.str;
                    default = toString source;
                  };
                  owner = lib.mkOption { type = lib.types.str; };
                  mode = lib.mkOption { type = lib.types.str; };
                };
              }
            );
          };
          options.fn = lib.mkOption {
            type = lib.types.attrs;
            default.pki.root_file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          };
        }
      )
    ];
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 4096;
    networking.hostName = "machine";
    environment.systemPackages = [
      pkgs.curl
      pkgs.util-linux
    ];
    realm = {
      enable = true;
      serviceDiscovery = {
        enable = true;
        address = "::1";
        catalog.fixture =
          lib.genAttrs
            [
              "postgresql-telegram-search"
              "redis-misskey"
              "meilisearch"
              "s3-https"
              "internet-proxy"
            ]
            (_: {
              address = "::1";
              port = 1;
              unit = "fixture.service";
            });
      };
    };
    vaultix.secrets.tg-search.path = toString (
      pkgs.writeText "dummy-search.env" "DATABASE_URL=postgresql://unused:dummy@unreachable/unused\n"
    );
    virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.telegram-search-app = {
        image = lib.mkForce "realm-container-fixture:test";
        imageFile = image;
        cmd = lib.mkForce [
          "launch"
          "${pkgs.nodejs}/bin/node"
          "${backend}"
        ];
      };
      containers.misskey = {
        image = lib.mkForce "realm-container-fixture:test";
        imageFile = image;
      };
    };
    systemd.services.realm-egress-telegram-search-postgresql = {
      requires = lib.mkForce [ ];
      after = lib.mkForce [ ];
      serviceConfig = {
        Type = lib.mkForce "simple";
        ExecStart = lib.mkForce "${pkgs.python3}/bin/python3 ${echo}";
      };
    };
    systemd.targets.postgresql = { };
    systemd.sockets.fixture-postgresql = {
      wantedBy = [ "sockets.target" ];
      listenStreams = [ "/run/postgresql/.s.PGSQL.5432" ];
      socketConfig = {
        SocketUser = "misskey";
        SocketGroup = "misskey";
        SocketMode = "0660";
      };
    };
    systemd.services.fixture-postgresql.serviceConfig = {
      User = "misskey";
      ExecStart = "${pkgs.python3}/bin/python3 ${echo}";
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("podman-misskey.service", timeout=180)
    machine.wait_for_unit("podman-telegram-search-app.service", timeout=180)
    with subtest("Telegram Search uses rootless keep-id and publishes a Unix socket"):
        machine.wait_until_succeeds("curl -sf --unix-socket /run/realm-telegram-search/backend/http.sock http://localhost/ | grep -x 0:0:mesh", timeout=30)
        machine.succeed("runuser -u telegram-search -- podman inspect telegram-search-app --format '{{.HostConfig.NetworkMode}}' | grep -x none")
        actual = machine.succeed("runuser -u telegram-search -- podman exec telegram-search-app node -p process.env.DATABASE_URL").strip()
        assert actual == "postgresql://telegram_search@127.0.0.1:15432/telegram_search?sslmode=disable", actual
        machine.fail("runuser -u nobody -- curl -sf --max-time 2 --unix-socket /run/realm-telegram-search/backend/http.sock http://localhost/")
        machine.fail("curl -sf --max-time 2 http://127.0.0.1:3336/")
    with subtest("the SOCKS adapter is bridged to the container through a Unix socket"):
        # The bridge service is socket-activated, so this also proves that
        # realm-helper receives the listening descriptor from systemd.
        machine.succeed(
            "runuser -u telegram-search -- ${pkgs.python3}/bin/python3 -c 'import socket; s=socket.socket(socket.AF_UNIX); s.connect(\"/run/realm/telegram-search/egress/socks.sock\"); s.sendall(b\"\\x05\\x01\\x00\"); assert s.recv(2) == b\"\\x05\\x00\"'"
        )
    with subtest("container receives prepared configuration unchanged"):
        expected = machine.succeed("cat ${source}")
        actual = machine.succeed("runuser -u misskey -- podman exec misskey cat /misskey/.config/default.yml")
        assert actual == expected
    with subtest("rootless keep-id mapping and Unix egress"):
        machine.wait_until_succeeds("curl -sf --unix-socket /run/realm-misskey/backend/http.sock http://localhost/ | grep -x 1000:1000:mesh", timeout=30)
    with subtest("backend socket is not exposed to unrelated users"):
        machine.fail("runuser -u nobody -- curl -sf --max-time 2 --unix-socket /run/realm-misskey/backend/http.sock http://localhost/")
    with subtest("container has no directly connected network"):
        machine.succeed("runuser -u misskey -- podman inspect misskey --format '{{.HostConfig.NetworkMode}}' | grep -x none")
        machine.fail("curl -sf --max-time 2 http://127.0.0.1:3012/")
  '';
}
