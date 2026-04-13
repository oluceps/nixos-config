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
}
