{
  flake.modules.nixos.meilisearch =
    {
      config,
      lib,
      ...
    }:
    {
      vaultix.secrets.meilisearch = {
        owner = "meilisearch";
        mode = "400";
      };
      systemd.services.meilisearch.environment.MEILI_NO_ANALYTICS = lib.mkForce "true";
      realm.workloads.meilisearch = {
        isolation.runtimePaths = [ "/run/meilisearch" ];
        ingress.http = {
          port = 17700;
          target = "127.0.0.1:7700";
          privateLoopback = true;
          service = "meilisearch";
          allowedIDs = config.realm.caddy.allowedIDs.meilisearch ++ [
            "spiffe://nyaw.xyz/service/misskey"
          ];
        };
      };
      services.meilisearch = {
        enable = true;
        listenAddress = "127.0.0.1";
        # settings.env = "production";
        settings.env = "development";
        masterKeyFile = config.vaultix.secrets.meilisearch.path;
      };
    };
}
