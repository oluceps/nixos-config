{ data, ... }:
{
  age.identityPaths = [ "/persist/keys/ssh_host_ed25519_key" ];
  rekey.hostPubkey = data.keys.hasturHostPubKey;
  services.openssh.hostKeys = [{
    path = "/persist/keys/ssh_host_ed25519_key";
    type = "ed25519";
  }];
}

