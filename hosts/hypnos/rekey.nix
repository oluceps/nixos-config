{ data, ... }:
{
  age = {
    identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    rekey.hostPubkey = data.keys.kaamblHostPubKey;
  };
}
