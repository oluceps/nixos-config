{ nixpkgs }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  inherit (pkgs) lib;
  evaluate =
    extra:
    (import (nixpkgs + "/nixos/lib/eval-config.nix") {
      inherit pkgs;
      modules = [
        ../nixosModules/realm-workloads.nix
        ../nixosModules/realm-spire.nix
        ../nixosModules/service-discovery.nix
        {
          networking.hostName = "fixture";
          system.stateVersion = "26.05";
          realm = {
            enable = true;
            serviceDiscovery = {
              enable = true;
              address = "fdcc::3";
            };
            workloads = {
              sender = {
                egress.receiver = {
                  service = "receiver";
                  verifyID = "spiffe://nyaw.xyz/service/receiver";
                  localPort = 13100;
                };
              };
              receiver = {
                ingress.http = {
                  port = 19429;
                  target = "127.0.0.1:3030";
                  privateLoopback = true;
                  consulService = "receiver";
                  allowedIDs = [ "spiffe://nyaw.xyz/service/sender" ];
                };
              };
            };
          };
          systemd.services.sender.serviceConfig = {
            User = "sender";
            ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
          };
          systemd.services.receiver.serviceConfig = {
            User = "receiver";
            ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
          };
          users.users.sender = {
            isSystemUser = true;
            group = "sender";
          };
          users.users.receiver = {
            isSystemUser = true;
            group = "receiver";
          };
          users.groups.sender = { };
          users.groups.receiver = { };
        }
      ]
      ++ extra;
    }).config;
  cfg = evaluate [ ];
  bad = evaluate [ { realm.workloads.receiver.ingress.http.allowedIDs = lib.mkForce [ ]; } ];
  realmAssertions =
    c: builtins.filter (a: !a.assertion && lib.hasPrefix "realm" a.message) c.assertions;
in
lib.runTests {
  testDeclarationsValid = {
    expr = lib.all (a: a.assertion) (realmAssertions cfg);
    expected = true;
  };
  testPrivateNetwork = {
    expr = cfg.systemd.services.sender.serviceConfig.PrivateNetwork;
    expected = true;
  };
  testNamespaceJoin = {
    expr = cfg.systemd.sockets.realm-local-sender-receiver.unitConfig.JoinsNamespaceOf;
    expected = "realm-net-sender.service";
  };
  testNoRuntimeSockets = {
    expr = cfg.systemd.services.sender.serviceConfig.TemporaryFileSystem;
    expected = [ "/run:ro" ];
  };
  testBackendPrivate = {
    expr = cfg.systemd.services.realm-backend-receiver-http.serviceConfig.PrivateNetwork;
    expected = true;
  };
  testOnlyIngressPublished = {
    expr = builtins.attrNames cfg.realm.serviceDiscovery.publish;
    expected = [ "receiver" ];
  };
  testPublishedUnit = {
    expr = cfg.realm.serviceDiscovery.publish.receiver.unit;
    expected = "realm-ingress-receiver-http.service";
  };
  testPublishedPort = {
    expr = cfg.realm.serviceDiscovery.publish.receiver.port;
    expected = 19429;
  };
  testIdentityBoundToProxy = {
    expr = cfg.realm.spire.registrations.realm-egress-sender-receiver.selectors;
    expected = [
      "systemd:id:realm-egress-sender-receiver.service"
      "unix:user:realm-sender"
    ];
  };
  testRejectEmptyPolicy = {
    expr = lib.any (a: !a.assertion) (realmAssertions bad);
    expected = true;
  };
  testSocketPermissions = {
    expr = cfg.systemd.sockets.realm-egress-sender-receiver.socketConfig.SocketMode;
    expected = "0660";
  };
  testNoCredentialCopy = {
    expr = cfg.systemd.services.realm-egress-sender-receiver.serviceConfig.LoadCredential or [ ];
    expected = [ ];
  };
}
