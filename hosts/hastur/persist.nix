{ user, ... }: {

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/etc/secureboot"
      "/var/log"
      "/var/lib"
      { directory = "/root/.yubico"; mode = "0700"; }
    ];
    users.${user} = {
      files = [
        ".npmrc"
      ];
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
        "Videos"
        "Music"
        "Security"
        "softwares"
        "Blog"
        "Games"
        ".npm-packages"
        ".npm"
        ".pip"
        "tools"
        "Vault"
        "calibreLib"
        ".cache"
        ".local"
        ".cargo"
        ".rustup"
        ".mozilla"
        ".config"
        ".FeelUOwn"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".yubico"; mode = "0700"; }
      ];
    };
  };
}
  
