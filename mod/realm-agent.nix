{
  flake.modules.nixos.realm =
    { config, lib, ... }:
    {
      # Isolated workloads opt in automatically in the reusable module. Keep
      # developer machines outside this rollout until explicitly enabled.
      realm.agent.enable = lib.mkDefault (
        !(builtins.elem config.networking.hostName [
          "hastur"
          "kaambl"
        ])
      );
    };
}
