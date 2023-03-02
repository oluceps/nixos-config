{ inputs, user, pkgs }:
[
  (inputs.nixpkgs
  + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix")
] ++ [

  (import ../../users.nix { inherit user pkgs; })
  {

    nix = {
      package = pkgs.nixVersions.stable;

      settings = {

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
        substituters = [
          "https://mirrors.bfsu.edu.cn/nix-channels/store"
          "https://cache.nixos.org"
        ];
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "${user}" ];
      };
    };
    # TODO: add agenix to livecd
    services.sing-box.enable = true;
    # only avaliable on hastur
    age.identityPaths = [ "/mnt/persist/keys/ssh_host_ed25519_key" ];

    age.secrets = {
      sing = {
        file = ../../secrets/sing.age;
        mode = "770";
        owner = user;
        group = user;
      };
      ssh = {
        file = ../../secrets/ssh.age;
        mode = "770";
        owner = user;
        group = user;
      };
    };

    environment.systemPackages = with pkgs;[
      (
        writeShellScriptBin "mount-os" ''
          #!/usr/bin/env bash
          echo "start mounting ..."
          doas mkdir /mnt/{persist,etc,var,boot,nix}
          doas mount -o compress=zstd,discard=async,noatime,subvol=nix /dev/nvme0n1p3 /mnt/nix
          doas mount -o compress=zstd,discard=async,noatime,subvol=persist /dev/nvme0n1p3 /mnt/persist
          doas mount /dev/nvme0n1p1 /mnt/boot
          doas mount -o bind /mnt/persist/etc /mnt/etc
          doas mount -o bind /mnt/persist/var /mnt/var
          echo "mount finished."
        ''
      )
      nftables
      tor
      iperf3
      i2p
      ethtool
      dnsutils
      autossh
      tcpdump
      nur-pkgs.sing-box
      netcat
      dog
      wget
      mtr-gui
      socat
      arti
      miniserve
      mtr
      wakelan
      netcat-gnu
      q
      nali
      lynx
      nethogs
      restic
      w3m
      whois
      dig
      wireguard-tools
      curl

      srm

      killall
      # common
      hexyl
      jq
      fx
      bottom
      lsd
      fd
      choose
      duf
      tokei
      procs

      exa

      lsof
      tree
      bat

      broot
      powertop
      ranger

      ripgrep

      qrencode
      lazygit
      b3sum
      unzip
      zip
      coreutils

      bpftools
      inetutils
      pciutils
      usbutils
    ];
  }
  inputs.home-manager.nixosModules.home-manager
  inputs.agenix.nixosModules.default

]
