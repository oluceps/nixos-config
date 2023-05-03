{ user, ... }: {

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/etc/secureboot"
      "/var/log"
      "/var/lib"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.${user} = {
      files = [
        ".npmrc"
      ];
      directories = [
        "Src"
        "Calib"
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        "Music"
        "tools"
        "Vault"
        { directory = "Priv"; mode = "0700"; }
        ".npm-packages"
        ".npm"
        ".pip"
        ".cache"
        ".local"
        ".cargo"
        ".rustup"
        ".mozilla"
        ".FeelUOwn"
        ".config"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
  };
}
  
