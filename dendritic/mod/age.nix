{ self, ... }:
let
  hostPrivKey = "/persist/keys/ssh_host_ed25519_key";
in
{
  flake.modules.nixos."age/hastur" =
    { config, ... }:
    {
      vaultix = {
        settings.hostPubkey = self.data.node.${config.networking.hostName}.ssh_key;
        secrets = {
          id = {
            mode = "400";
            owner = config.identity.user;
          };
          sing = { };
          age = { };
          atuin = {
            owner = config.identity.user;
            mode = "400";
          };
          atuin_key = {
            owner = config.identity.user;
            mode = "400";
          };
          sing-server = { };
          id_sk = {
            owner = config.identity.user;
            mode = "400";
          };
          "general.toml" = { };
        };
      };
      services.openssh.hostKeys = [
        {
          path = hostPrivKey;
          type = "ed25519";
        }
      ];
    };
  flake.modules.nixos."age/eihort" =
    { config, ... }:
    {
      vaultix = {
        settings.hostPubkey = self.data.node.${config.networking.hostName}.ssh_key;
        secrets = {
          nuan = { };
          cfd = { };
          "general.toml" = { };
          tg-session = {
            mode = "640";
            owner = "root";
            group = "root";
            name = "tg-session";
          };
          sing = { };
          tgexp = { };
          tg-env = {
            mode = "640";
            owner = "root";
            group = "root";
            name = "tg-env";
          };
          pocketid = {
            mode = "400";
            owner = config.services.pocket-id.user;
          };

          age = { };
          atuin = {
            owner = config.identity.user;
            mode = "400";
          };
          atuin_key = {
            owner = config.identity.user;
            mode = "400";
          };
        };
      };
      services.openssh.hostKeys = [
        {
          path = hostPrivKey;
          type = "ed25519";
        }
      ];
    };
  flake.modules.nixos."age/abhoth" =
    { config, ... }:
    {

      services.openssh.hostKeys = [
        {
          path = hostPrivKey;
          type = "ed25519";
        }
      ];
      vaultix = {
        settings.hostPubkey = config.data.node.${config.networking.hostName}.ssh_key;

        secrets = {
          # postfix-sasl = { };
          stalwart = { };
        };
      };
    };
}
