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
          garage = { };
          dae = {
            owner = "root";
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
}
