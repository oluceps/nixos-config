{
  reIf,
  lib,
  config,
  ...
}:
reIf {
  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    # plugins = with config.services.matrix-synapse.package.plugins; [
    #   matrix-synapse-s3-storage-provider
    # ];
    settings = {
      server_name = "nyaw.xyz";
      public_baseurl = "https://matrix.nyaw.xyz";
      signing_key_path = config.vaultix.secrets.synapse.path;

      enable_authenticated_media = true;

      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;

      enable_registration = true;
      registration_requires_token = true;

      # media_storage_providers = [
      #   {
      #     module = "s3_storage_provider.S3StorageProviderBackend";
      #     store_local = true;
      #     store_remote = true;
      #     store_synchronous = true;
      #     config = {
      #       bucket = b2.bucket;
      #       endpoint_url = b2.endpoint;
      #     };
      #   }
      # ];

      listeners = [
        {
          bind_addresses = [ "127.0.0.1" ];
          port = 8196;
          tls = false;
          type = "http";
          x_forwarded = true;
          resources = [
            {
              compress = true;
              names = [
                "client"
                "federation"
              ];
            }
          ];
        }
      ];

      media_retention = {
        remote_media_lifetime = "14d";
      };

      experimental_features = {
        # Room summary api
        msc3266_enabled = true;
        # Removing account data
        msc3391_enabled = true;
        # Thread notifications
        msc3773_enabled = true;
        # Remotely toggle push notifications for another client
        msc3881_enabled = true;
        # Remotely silence local notifications
        msc3890_enabled = true;
        # Remove legacy mentions
        msc4210_enabled = true;
      };

      rc_admin_redaction = {
        per_second = 1000;
        burst_count = 10000;
      };
    };
  };

}
