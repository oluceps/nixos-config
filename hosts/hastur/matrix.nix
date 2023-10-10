{ config, pkgs, ... }:
let
  conf = {
    default_server_config = {
      "m.homeserver" = {
        base_url = config.services.matrix-synapse.settings.public_baseurl;
        server_name = config.services.matrix-synapse.settings.server_name;
      };
    };
    show_labs_settings = true;
  };
in
{

  services.matrix-synapse = {
    enable = true;
    withJemalloc = true;
    settings = {
      server_name = "nyaw.xyz";
      public_baseurl = "https://matrix.nyaw.xyz";
      signing_key_path = config.age.secrets.matrix-synapse.path;

      extra_well_known_client_content = {
        "org.matrix.msc3575.proxy" = {
          "url" = "https://syncv3.nyaw.xyz";
        };
      };

      dynamic_thumbnails = true;
      allow_public_rooms_over_federation = true;

      enable_registration = true;
      registration_requires_token = true;

      listeners = [{
        bind_addresses = [ "10.0.1.3" ];
        port = 8196;
        tls = false;
        type = "http";
        x_forwarded = true;
        resources = [{
          compress = true;
          names = [ "client" "federation" ];
        }];
      }];

      media_retention = {
        remote_media_lifetime = "14d";
      };

      oidc_providers = [{
        idp_id = "keycloak";
        idp_name = "id.nichi.co";
        issuer = "https://id.nichi.co/realms/nichi";
        client_id = "synapse";
        client_secret_path = config.sops.secrets.matrix-synapse-oidc.path;
        scopes = [ "openid" "profile" ];
        allow_existing_users = true;
        backchannel_logout_enabled = true;
        user_mapping_provider.config = {
          confirm_localpart = true;
          localpart_template = "{{ user.preferred_username }}";
          display_name_template = "{{ user.name }}";
        };
      }];

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
      };
    };

    sliding-sync = {
      enable = true;
      environmentFile = config.age.secrets.sliding-sync.path;
      settings = {
        SYNCV3_SERVER = config.services.matrix-synapse.settings.public_baseurl;
      };
    };
  };
}
