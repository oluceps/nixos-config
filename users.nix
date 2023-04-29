{ pkgs
, user
, data
, ...
}: {
  security.doas = {
    enable = true;
    wheelNeedsPassword = false;
  };

  users = {
    mutableUsers = pkgs.lib.mkForce false;
    users.root = {
      initialHashedPassword = pkgs.lib.mkForce data.keys.hashedPasswd;
      openssh.authorizedKeys.keys = [ data.keys.sshPubKey ];
    };
    users.${user} = {
      initialHashedPassword = pkgs.lib.mkDefault data.keys.hashedPasswd;
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
