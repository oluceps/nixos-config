{ pkgs
, user
, data
, lib
, ...
}: {
  security.doas = {
    enable = true;
    wheelNeedsPassword = false;
  };

  users = {
    mutableUsers = lib.mkForce false;
    users.root = {
      initialHashedPassword = lib.mkForce data.keys.hashedPasswd;
      openssh.authorizedKeys.keys = [ data.keys.sshPubKey ];
    };
    users.${user} = {
      initialHashedPassword = lib.mkDefault data.keys.hashedPasswd;
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

      openssh.authorizedKeys.keys = [ data.keys.sshPubKey ];
    };
    users.root.shell = pkgs.bash;

    users.proxy = {
      isSystemUser = true;
      group = "nogroup";
    };
  };
  security.sudo = {
    enable = lib.mkForce false;
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
