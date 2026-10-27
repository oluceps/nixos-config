{
  flake.modules.nixos.realm =
    { config, lib, ... }:
    let
      # Roll out application namespaces, never the host-network gateways or
      # developer machines. A workload without Internet egress keeps DNS local.
      workloads =
        {
          azasos = [
            "ntfy"
            "subs"
          ];
          abhoth = [
            "alloy"
            "rustypaste"
          ];
          nodens = [ "alloy" ];
          uubboo = [ "alloy" ];
        }
        .${config.networking.hostName} or [ ];
    in
    {
      realm.workloads = lib.genAttrs workloads (name: {
        transparent = {
          enable = true;
          internetRoute = if config.realm.workloads.${name}.http.internet then "internet" else null;
        };
      });
    };
}
