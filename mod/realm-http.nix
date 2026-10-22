{ self, ... }:
{
  flake.modules.nixos.realm =
    { config, lib, ... }:
    {
      config.realm.http.gateways.eihort = {
        hosts = config.data.serviceHosts.eihort;
        service = "s3-https";
        verifyID = config.realm.caddy.entrypointID;
      };
      options.realm.http.gatewayClientIDs = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        readOnly = true;
        description = "Caller identities collected from internal HTTPS declarations across the cluster.";
        default = lib.mapAttrs (
          _: gateway:
          lib.unique (
            lib.concatLists (
              lib.mapAttrsToList (
                _: system:
                map (w: w.spiffeID) (
                  builtins.attrValues (
                    lib.filterAttrs (
                      _: w: w.enable && lib.any (domain: lib.elem domain gateway.hosts) w.http.internal
                    ) system.config.realm.workloads
                  )
                )
              ) (lib.filterAttrs (_: system: system.config.realm.enable or false) self.nixosConfigurations)
            )
          )
        ) config.realm.http.gateways;
      };
    };
}
