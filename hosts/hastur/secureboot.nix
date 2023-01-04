{ config, user, ... }: {
  boot.lanzaboote = {
    enable = true;
    privateKeyFile = "/persist/etc/secureboot/keys/db/db.key";
    publicKeyFile = "/persist/etc/secureboot/keys/db/db.pem";
  };
}

