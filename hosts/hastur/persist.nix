{ user, ... }: {

  environment.persistence."/persist" = {
    hideMounts = true;
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
        ".mongoshrc.js"
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
        { directory = "Sec"; mode = "0700"; }
        ".npm-packages"
        ".npm"
        ".pip"
        ".cache"
        ".local"
        ".mc"
        ".cargo"
        ".rustup"
        ".mozilla"
        ".FeelUOwn"
        ".config"
        ".mongodb"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
  };
}
  
