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
          consulService = "meilisearch";
          allowedIDs = [
            "spiffe://nyaw.xyz/service/misskey"
            "spiffe://nyaw.xyz/service/caddy"
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
