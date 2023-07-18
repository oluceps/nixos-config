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
        ".mongoshrc.js"
        ".gitconfig"
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
        ".factorio"
        ".cargo"
        ".rustup"
        ".mozilla"
        ".FeelUOwn"
        ".config"
        ".mongodb"
        ".vscode"
        "Games"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
  };
}
  
