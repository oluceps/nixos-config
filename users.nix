{ config
, pkgs
, user
, ...
}: {
  security.doas = {
    enable = true;
    extraConfig = ''
      permit nopass :wheel
    '';
  };


  users = {
    mutableUsers = false;
    users.root.initialHashedPassword = "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
    users.${user} = {
      initialHashedPassword = "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
      isNormalUser = true;
      uid = 1000;
      group = "${user}";
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
        "adbusers"
      ]; # Enable ‘sudo’ for the user.
      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG"
      ];
    };
    users.root.shell = pkgs.zsh;

    users.proxy = {
      isSystemUser = true;
      group = "proxy";
    };

    groups = {
      ${user} = { };
      proxy = { };
    };
  };
  security.sudo = {
    enable = false;
    extraRules = [
      {
        users = [ "${user}" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
