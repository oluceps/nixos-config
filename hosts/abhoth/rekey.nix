{ data, ... }:

let
  hostPrivKey = "/var/lib/ssh/ssh_host_ed25519_key";
in
{

  services.openssh.hostKeys = [
    {
      path = hostPrivKey;
      type = "ed25519";
    }
  ];
  age = {
    identityPaths = [ hostPrivKey ];
    rekey.hostPubkey = data.keys.abhothHostPubKey;

    secrets = {
      hyst-us = {
        rekeyFile = ../../sec/hyst-us.age;
        mode = "640";
        owner = "root";
        group = "users";
        name = "hyst-us.yaml";
      };
      syncv3 = {
        rekeyFile = ../../sec/syncv3.age;
      };
      wgab = {
        rekeyFile = ../../sec/wgab.age;
      };
    };
  };
}
