{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.realm.serviceDiscovery;
  checkFormat = pkgs.formats.json { };

  unitEnabled =
    unit:
    if lib.hasSuffix ".service" unit then
      config.systemd.services.${lib.removeSuffix ".service" unit}.enable or false
    else
      config.systemd.sockets.${lib.removeSuffix ".socket" unit}.enable or false;

  services = lib.mapAttrsToList (
    name: service:
    let
      id = "${config.networking.hostName}-${name}";
    in
    {
      inherit id name;
      inherit (service) address tags;
      checks = [
        {
          id = "${id}-unit";
          name = "${service.unit} is active";
          args = [
            "${config.systemd.package}/bin/systemctl"
            "is-active"
            "--quiet"
            service.unit
          ];
          interval = "10s";
          timeout = "2s";
          status = "critical";
        }
      ]
      ++ service.checks;
    }
    // lib.optionalAttrs (service.port != null) {
      inherit (service) port;
    }
  ) cfg.publish;
in
{
  options.realm.serviceDiscovery = {
    enable = lib.mkEnableOption "service registration with the local Consul agent";

    address = lib.mkOption {
      type = lib.types.str;
      description = "Default service address that other nodes can reach.";
    };

    publish = lib.mkOption {
      default = { };
      description = "Services to register with Consul, indexed by their DNS service name.";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              unit = lib.mkOption {
                type = lib.types.strMatching ".+\\.(service|socket)";
                default = "${name}.service";
                description = "System service or socket unit to check.";
              };

              address = lib.mkOption {
                type = lib.types.str;
                default = cfg.address;
                defaultText = lib.literalExpression "config.realm.serviceDiscovery.address";
                description = "Service address that other nodes can reach.";
              };

              port = lib.mkOption {
                type = lib.types.nullOr lib.types.port;
                default = null;
                description = "Optional service port for SRV queries.";
              };

              tags = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Tags for Consul service queries.";
              };

              checks = lib.mkOption {
                type = lib.types.listOf checkFormat.type;
                default = [ ];
                description = "Extra Consul health checks, in addition to the unit check.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: service: [
        {
          assertion =
            builtins.stringLength name <= 63 && builtins.match "[a-z0-9]([a-z0-9-]*[a-z0-9])?" name != null;
          message = "realm.serviceDiscovery.publish.${name}: use a DNS label with lowercase letters, digits, and internal hyphens.";
        }
        {
          assertion = unitEnabled service.unit;
          message = "realm.serviceDiscovery.publish.${name}: ${service.unit} must be declared and enabled.";
        }
      ]) cfg.publish
    );

    services.consul = {
      enable = true;
      extraConfig = {
        enable_local_script_checks = true;
        inherit services;
      };
    };
  };
}
