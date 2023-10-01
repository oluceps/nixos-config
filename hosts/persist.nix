{ user, ... }: {

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/etc/NetworkManager"
      # "/var/log"
      # "/var/lib"
    ];
    users.${user} = {
      files = [
        ".npmrc"
        ".mongoshrc.js"
        ".gitconfig"
      ];
      directories = [
        "Src"
        "Books"
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        "Music"
        "Tools"
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
  
