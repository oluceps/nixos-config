{ inputs, user, pkgs, data, lib }:
[
  (inputs.nixpkgs
  + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix")
] ++ [

  (import ../../users.nix { inherit user pkgs data lib; })
  {
    isoImage = {
      compressImage = true;
      squashfsCompression = "zstd -Xcompression-level 6";
    };



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
    services = {
      sing-box.enable = true;
      pcscd.enable = true;
    };
    environment.systemPackages = with pkgs;[
      (
        writeShellScriptBin "mount-os" ''
          #!/usr/bin/env bash
          echo "start mounting ..."
          doas mkdir /mnt/{persist,etc,var,boot,nix}
          doas mount -o compress=zstd,discard=async,noatime,subvol=nix /dev/$1 /mnt/nix
          doas mount -o compress=zstd,discard=async,noatime,subvol=persist /dev/$1 /mnt/persist
          doas mount /dev/nvme0n1p1 /mnt/boot
          doas mount -o bind /mnt/persist/etc /mnt/etc
          doas mount -o bind /mnt/persist/var /mnt/var
          echo "mount finished."
        ''
      )
      rage
      nftables
      tor
      iperf3
      i2p
      ethtool
      dnsutils
      autossh
      tcpdump
      sing-box
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

]
