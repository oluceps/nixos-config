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
    fs.rmSync(socket, { force: true });
    http.createServer((req, res) => {
      const client = net.createConnection(5432, '127.0.0.1', () => client.write('mesh'));
      client.on('data', (data) => { res.end(process.getuid()+':'+process.getgid()+':'+data); client.end(); });
      client.on('error', () => { res.statusCode = 503; res.end('unreachable'); });
    }).listen(socket, () => fs.chmodSync(socket, 0o660));
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
    db: { db: fixture, user: fixture, pass: dummy }
    redis: {}
    meilisearch: { apiKey: dummy }
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
      (import ../mod/misskey.nix).flake.modules.nixos.misskey
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
      };
    };
    virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.misskey = {
        image = lib.mkForce "realm-container-fixture:test";
        imageFile = image;
      };
    };
    systemd.services.realm-egress-misskey-postgresql = {
      requires = lib.mkForce [ ];
      after = lib.mkForce [ ];
      serviceConfig = {
        Type = lib.mkForce "simple";
        ExecStart = lib.mkForce "${pkgs.python3}/bin/python3 ${echo}";
      };
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("podman-misskey.service", timeout=180)
    with subtest("rootless keep-id mapping and Unix egress"):
        machine.wait_until_succeeds("curl -sf --unix-socket /run/realm-misskey/backend/http.sock http://localhost/ | grep -x 1000:1000:mesh", timeout=30)
    with subtest("backend socket is not exposed to unrelated users"):
        machine.fail("runuser -u nobody -- curl -sf --max-time 2 --unix-socket /run/realm-misskey/backend/http.sock http://localhost/")
    with subtest("container has no directly connected network"):
        machine.succeed("runuser -u misskey -- podman inspect misskey --format '{{.HostConfig.NetworkMode}}' | grep -x none")
        machine.fail("curl -sf --max-time 2 http://127.0.0.1:3012/")
  '';
}
