{ config
, pkgs
, ...
}: {
  networking = {
    hostName = "livecd"; # Define your hostname.
    # replicates the default behaviour.
    enableIPv6 = true;

  };
}
