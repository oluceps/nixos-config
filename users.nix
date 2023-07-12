{ pkgs
, user
, data
, lib
, ...
}: {

  security = {
    doas = {
      enable = false;
      wheelNeedsPassword = false;
    };
    sudo = {
      enable = lib.mkForce true;
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
  };

  users = {
    mutableUsers = lib.mkForce false;
    users.root = {
      initialHashedPassword = lib.mkForce data.keys.hashedPasswd;
      openssh.authorizedKeys.keys = with data.keys;[ sshPubKey ];
    };
    users.${user} = {
      initialHashedPassword = lib.mkDefault data.keys.hashedPasswd;
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "kvm"
        "adbusers"
        "docker"
      ];
      shell = pkgs.bash;

      openssh.authorizedKeys.keys = with data.keys;[ sshPubKey ];
    };
    users.root.shell = pkgs.bash;

    users.proxy = {
      isSystemUser = true;
      group = "nogroup";
    };
  };
}
