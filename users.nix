{ pkgs
, user
, ...
}: {
  security.doas = {
    enable = true;
    wheelNeedsPassword = false;
    # extraRules =
    #   [
    #     {
    #       users = [ user ];
    #       noPass = true;
    #     }
    #   ];
  };

  users = {
    mutableUsers = false;
    users.root = {
      initialHashedPassword = pkgs.lib.mkForce
        "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG"
      ];
    };
    users.${user} = {
      initialHashedPassword = pkgs.lib.mkDefault
        "$6$Sa0gWbsXht6Uhr1M$ZwC76OJYx6fdLEjmo4xC4R7PEqY7DU1SN1cIYabZpQETV3npJ6cAoMjByPVQRqrOeHBjYre1ROMim4LgyQZ731";
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "kvm"
        "libvirtd"
        "qemu-libvirtd"
        "docker"
        "adbusers"
      ];
      shell = pkgs.bash;

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG"
      ];
    };
    users.root.shell = pkgs.zsh;

    users.proxy = {
      isSystemUser = true;
      group = "nogroup";
    };
    # groups."riro" = { };
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
