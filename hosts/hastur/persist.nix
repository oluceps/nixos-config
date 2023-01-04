{ user, ... }: {

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/etc/secureboot"
      "/var/log"
      "/var/lib"
    ];
    users.${user} = {
      # files = [
      #   ".npmrc"
      # ];
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
        "tools"
        "Vault"
        "calibreLib"
        ".cache"
        ".local"
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
  
