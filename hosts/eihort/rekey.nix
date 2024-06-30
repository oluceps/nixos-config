{ data, ... }:
{
  age = {
    identityPaths = [ "/persist/keys/ssh_host_ed25519_key" ];
    rekey.hostPubkey = data.keys.eihortHostPubKey;

    secrets = { };
  };
}
