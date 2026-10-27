{ nixpkgs }:
let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  inherit (pkgs) lib;
  evaluate =
    extra:
    (import (nixpkgs + "/nixos/lib/eval-config.nix") {
      inherit pkgs;
      modules = [
        ../nixosModules/realm-agent.nix
        ../nixosModules/realm-spire.nix
        ../nixosModules/service-discovery.nix
        {
          system.stateVersion = "26.05";
          realm = {
            enable = true;
            serviceDiscovery = {
              enable = true;
              address = "::1";
            };
            workloads.fixture.transparent.enable = true;
          };
          systemd.services.fixture.serviceConfig = {
            User = "fixture";
            ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
          };
        }
      ]
      ++ extra;
    }).config;
  failures =
    c:
    map (a: a.message) (lib.filter (a: !a.assertion && lib.hasPrefix "realm" a.message) c.assertions);
  cfg = evaluate [ ];
  disabled = evaluate [ { realm.workloads.fixture.transparent.enable = lib.mkForce false; } ];
  unsafe = evaluate [ { realm.workloads.fixture.isolation.privateNetwork = false; } ];
  badRoute = evaluate [ { realm.workloads.fixture.transparent.internetRoute = "missing"; } ];
  overlap = evaluate [ { realm.workloads.fixture.transparent.tcpPort = 15053; } ];
  dynamic = evaluate [
    {
      systemd.services.fixture.serviceConfig = {
        User = lib.mkForce "fixture";
        DynamicUser = true;
      };
    }
  ];
  implicitDynamic = evaluate [
    {
      systemd.services.fixture.serviceConfig = {
        User = lib.mkForce "";
        DynamicUser = true;
      };
    }
  ];
  wrongUser = evaluate [ { systemd.services.fixture.serviceConfig.User = lib.mkForce "other"; } ];
in
assert failures cfg == [ ];
assert failures dynamic == [ ];
assert failures implicitDynamic == [ ];
assert lib.any (lib.hasInfix "configured workload user") (failures wrongUser);
assert !(disabled.systemd.services ? realm-agent);
assert lib.any (lib.hasInfix "isolated") (failures unsafe);
assert lib.any (lib.hasInfix "internetRoute") (failures badRoute);
assert lib.any (lib.hasInfix "overlap") (failures overlap);
assert cfg.users.users.rnet-fixture.group == "fixture";
assert builtins.elem "realm-agent.service" cfg.systemd.services.fixture.wants;
assert !(builtins.elem "realm-agent.service" cfg.systemd.services.fixture.requires);
assert lib.any (lib.hasInfix "gate --socket /run/realm-agent/fixture/control.sock")
  cfg.systemd.services.fixture.serviceConfig.ExecStartPre;
assert cfg.systemd.services.realm-agent.serviceConfig.KillMode == "control-group";
{
  passed = true;
  config = cfg.systemd.services.realm-agent.serviceConfig.ExecStart;
}
