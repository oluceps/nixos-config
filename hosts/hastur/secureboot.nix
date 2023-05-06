{ ... }: {
  boot = {
    bootspec.enable = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/persist/etc/secureboot";
    };
  };
}

