{ config
, pkgs
, ...
}: {
  users = {
    users.riro = {
      isNormalUser = true;
      uid = 1000;
      group = "riro";
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
        "audio"
        "libvirtd"
        "qemu-libvirtd"
        "kvm"
        "logindev"
        "plugdev"
      ]; # Enable ‘sudo’ for the user.
      shell = pkgs.fish;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG riro@hastur"
      ];
    };
    users.root.shell = pkgs.zsh;

    users.proxy = {
      isSystemUser = true;
      group = "proxy";
    };

    groups = {
      riro = { };
      proxy = { };
    };
  };
  security.sudo.extraRules = [
    {
      users = [ "riro" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
