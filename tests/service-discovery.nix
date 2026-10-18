{ nixpkgs }:
let
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  inherit (pkgs) lib;

  evaluate =
    modules:
    (import (nixpkgs + "/nixos/lib/eval-config.nix") {
      inherit pkgs;
      modules = [
        ../nixosModules/service-discovery.nix
        {
          networking.hostName = "test-node";
          system.stateVersion = "26.05";
        }
      ]
      ++ modules;
    }).config;

  published = {
    realm.serviceDiscovery = {
      enable = true;
      address = "fdcc::3";
      publish.demo = {
        unit = "demo.service";
        port = 8888;
      };
    };
    systemd.services.demo.serviceConfig.ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
  };

  enabled = evaluate [ published ];
  disabled = evaluate [ { } ];
  portless = evaluate [
    published
    { realm.serviceDiscovery.publish.demo.port = lib.mkForce null; }
  ];
  socket = evaluate [
    published
    {
      realm.serviceDiscovery.publish.demo.unit = lib.mkForce "demo.socket";
      systemd.sockets.demo.listenStreams = [ "8888" ];
      systemd.services.demo.enable = false;
    }
  ];
  custom = evaluate [
    published
    {
      realm.serviceDiscovery.publish.demo = {
        address = "fdcc:3::10";
        tags = [ "http" ];
        checks = [
          {
            tcp = "[fdcc:3::10]:8888";
            interval = "10s";
          }
        ];
      };
    }
  ];
  container = evaluate [
    (
      { config, ... }:
      {
        realm.serviceDiscovery = {
          enable = true;
          address = "fdcc::3";
          publish.demo = {
            unit = "${config.virtualisation.oci-containers.containers.demo.serviceName}.service";
            port = 8888;
          };
        };
        virtualisation.oci-containers = {
          backend = "podman";
          containers.demo = {
            image = "docker.io/library/nginx:alpine";
            ports = [ "[fdcc::3]:8888:80" ];
          };
        };
      }
    )
  ];
  missingUnit = evaluate [
    published
    { realm.serviceDiscovery.publish.demo.unit = lib.mkForce "missing.service"; }
  ];
  disabledUnit = evaluate [
    published
    { systemd.services.demo.enable = false; }
  ];
  invalidName = evaluate [
    published
    { realm.serviceDiscovery.publish."Invalid.Name".unit = "demo.service"; }
  ];
  invalidPort = evaluate [
    published
    { realm.serviceDiscovery.publish.demo.port = lib.mkForce 65536; }
  ];

  clusterModule = (import ../mod/consul.nix).flake.modules.nixos.consul;
  cluster =
    hostName:
    evaluate [
      clusterModule
      (
        { lib, ... }:
        {
          options.data = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
          };
          config = {
            networking.hostName = lib.mkForce hostName;
            data.node = {
              eihort.unique_addr_nomask = "fdcc::3";
              abhoth.unique_addr_nomask = "fdcc::5";
              nodens.unique_addr_nomask = "fdcc::8";
              hastur.unique_addr_nomask = "fdcc::1";
            };
          };
        }
      )
    ];
  server = cluster "eihort";
  client = cluster "hastur";

  allPass =
    config:
    !lib.any (a: !a.assertion && lib.hasPrefix "realm.serviceDiscovery." a.message) config.assertions;
  service = config: builtins.head config.services.consul.extraConfig.services;

  tests = {
    testDisabled = {
      expr = {
        inherit (disabled.services.consul) enable extraConfig;
      };
      expected = {
        enable = false;
        extraConfig = { };
      };
    };
    testRegistration = {
      expr = removeAttrs (service enabled) [ "checks" ];
      expected = {
        id = "test-node-demo";
        name = "demo";
        address = "fdcc::3";
        port = 8888;
        tags = [ ];
      };
    };
    testUnitCheck = {
      expr = builtins.head (service enabled).checks;
      expected = {
        id = "test-node-demo-unit";
        name = "demo.service is active";
        args = [
          "${enabled.systemd.package}/bin/systemctl"
          "is-active"
          "--quiet"
          "demo.service"
        ];
        interval = "10s";
        timeout = "2s";
        status = "critical";
      };
    };
    testLocalChecksOnly = {
      expr = {
        local = enabled.services.consul.extraConfig.enable_local_script_checks;
        remote = enabled.services.consul.extraConfig.enable_script_checks or false;
      };
      expected = {
        local = true;
        remote = false;
      };
    };
    testPortless = {
      expr = (service portless) ? port;
      expected = false;
    };
    testSocketActivation = {
      expr = {
        valid = allPass socket;
        unit = lib.last (builtins.head (service socket).checks).args;
      };
      expected = {
        valid = true;
        unit = "demo.socket";
      };
    };
    testCustomEndpoint = {
      expr = {
        inherit (service custom) address tags;
        check = lib.last (service custom).checks;
      };
      expected = {
        address = "fdcc:3::10";
        tags = [ "http" ];
        check = {
          tcp = "[fdcc:3::10]:8888";
          interval = "10s";
        };
      };
    };
    testContainerUnit = {
      expr = {
        valid = allPass container;
        unit = lib.last (builtins.head (service container).checks).args;
        port = (service container).port;
      };
      expected = {
        valid = true;
        unit = "podman-demo.service";
        port = 8888;
      };
    };
    testMissingUnit = {
      expr = allPass missingUnit;
      expected = false;
    };
    testDisabledUnit = {
      expr = allPass disabledUnit;
      expected = false;
    };
    testInvalidName = {
      expr = allPass invalidName;
      expected = false;
    };
    testInvalidPort = {
      expr = (builtins.tryEval (builtins.deepSeq (service invalidPort) true)).success;
      expected = false;
    };
    testServer = {
      expr = {
        inherit (server.services.consul.extraConfig)
          server
          bootstrap_expect
          retry_join
          domain
          datacenter
          client_addr
          ;
        address = server.realm.serviceDiscovery.address;
      };
      expected = {
        server = true;
        bootstrap_expect = 3;
        retry_join = [
          "fdcc::3"
          "fdcc::5"
          "fdcc::8"
        ];
        domain = "mesh.nyaw.xyz";
        datacenter = "nyaw";
        client_addr = "127.0.0.1";
        address = "fdcc::3";
      };
    };
    testAdditionalServers = {
      expr =
        map
          (
            hostName:
            let
              config = cluster hostName;
            in
            {
              inherit (config.services.consul.extraConfig) server bootstrap_expect;
              address = config.realm.serviceDiscovery.address;
            }
          )
          [
            "abhoth"
            "nodens"
          ];
      expected = [
        {
          server = true;
          bootstrap_expect = 3;
          address = "fdcc::5";
        }
        {
          server = true;
          bootstrap_expect = 3;
          address = "fdcc::8";
        }
      ];
    };
    testClient = {
      expr = {
        inherit (client.services.consul.extraConfig) server retry_join;
        bootstrap = client.services.consul.extraConfig ? bootstrap_expect;
        address = client.realm.serviceDiscovery.address;
        services = client.services.consul.extraConfig.services;
      };
      expected = {
        server = false;
        retry_join = [
          "fdcc::3"
          "fdcc::5"
          "fdcc::8"
        ];
        bootstrap = false;
        address = "fdcc::1";
        services = [ ];
      };
    };
    testMeshBinding = {
      expr = {
        inherit (client.services.consul) forceAddrFamily interface;
        passing = client.services.consul.extraConfig.dns_config.only_passing;
      };
      expected = {
        forceAddrFamily = "ipv6";
        interface = {
          bind = "anchor-0";
          advertise = "anchor-0";
        };
        passing = true;
      };
    };
    testDNSDelegation = {
      expr = client.services.resolved.dnsDelegates.mesh.Delegate;
      expected = {
        DNS = [ "127.0.0.1:8600" ];
        Domains = [ "~mesh.nyaw.xyz" ];
        DefaultRoute = false;
      };
    };
    testRuntimeAddressFile = {
      expr = {
        source = client.environment.etc."consul-addrs.json".source;
        directory = client.systemd.services.consul.serviceConfig.RuntimeDirectory;
      };
      expected = {
        source = "/run/consul/addrs.json";
        directory = "consul";
      };
    };
    testPrivateDNSSECAnchors = {
      expr =
        let
          anchors = lib.splitString "\n" client.environment.etc."dnssec-trust-anchors.d/consul.negative".text;
        in
        lib.all (domain: builtins.elem domain anchors) [
          "mesh.nyaw.xyz"
          "lan"
          "home.arpa"
          "d.f.ip6.arpa"
          "16.172.in-addr.arpa"
          "31.172.in-addr.arpa"
        ];
      expected = true;
    };
  };
  failures = lib.runTests tests;
in
if failures == [ ] then
  { passed = builtins.length (builtins.attrNames tests); }
else
  throw (builtins.toJSON failures)
