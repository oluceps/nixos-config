{
  flake.modules.nixos.realm-internet =
    { config, ... }:
    {
      imports = [ ../nixosModules/realm-internet.nix ];

      realm.internet = {
        enable = true;
        allowedIDs = map (n: config.realm.servicePrefix + n) [
          "misskey"
          "grafana"
          "immich-ml"
          "jellyfin"
          "vaultwarden"
          "forgejo"
          "ncps"
          "synapse"
          "calibre"
          "mautrix-telegram"
          "ntfy"
          "subs"
          "pocket-id"
        ];
        extraConnectPolicies.synapse-federation = {
          identities = [ "${config.realm.servicePrefix}synapse" ];
          ports = [ 8448 ];
        };
      };
    };
}
