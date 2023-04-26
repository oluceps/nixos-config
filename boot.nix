{ lib
, ...
}: {
  boot = {
    # Use the systemd-boot EFI boot loader.
    tmp = {
      useTmpfs = true;
      tmpfsSize = "80%";
    };

    loader = {
      systemd-boot.enable = lib.mkForce false;
      # grub2-theme = {
      #   enable = true;
      #   theme = "whitesur";
      #   screen = "1080p";
      #   splashImage =
      #     let
      #       img = pkgs.fetchurl {
      #         url = "https://pbs.twimg.com/media/Fch6xMNacAM-EJS?format=jpg";
      #         name = "background.jpg";
      #         hash = "sha256-gw8PT8PSr9Gz0cflx2EOqjTsxHeJIJeCawrz9l7kvFI=";
      #       };
      #       img-resized = pkgs.runCommand "background.jpg"
      #         {
      #           nativeBuildInputs = with pkgs; [ imagemagick ];
      #         } "convert -resize 1920x1080 ${img} $out";
      #     in
      #     "${img-resized}";
      # };
      grub = {
        enable = false;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
    };
    supportedFilesystems = [ "ntfs" "tcp_bbr" ];
    kernel.sysctl = {
      "kernel.panic" = 10;
      "kernel.sysrq" = 1;
      # max read buffer
      # max write buffer
      "fs.file-max" = 500000;
      # default read buffer
      "net.core.rmem_default" = 65536;
      # default write buffer
      "net.core.wmem_default" = 65536;
      # max processor input queue
      #"net.core.netdev_max_backlog" = 4096;
      # max backlog

      # Ignore ICMP broadcasts to avoid participating in Smurf attacks
      "net.ipv4.icmp_echo_ignore_broadcasts" = 0;
      # Ignore bad ICMP errors
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      # Reverse-path filter for spoof protection
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.wan.rp_filter" = 0;
      # SYN flood protection
      "net.ipv4.tcp_syncookies" = 0;
      # Do not accept ICMP redirects (prevent MITM attacks)
      "net.ipv4.conf.all.accept_redirects" = 1;
      "net.ipv4.conf.default.accept_redirects" = 1;
      "net.ipv4.conf.all.secure_redirects" = 1;
      "net.ipv4.conf.default.secure_redirects" = 1;
      "net.ipv6.conf.all.accept_redirects" = 1;
      "net.ipv6.conf.default.accept_redirects" = 1;
      # Protect against tcp time-wait assassination hazards
      "net.ipv4.tcp_rfc1337" = 1;
      # TCP Fast Open (TFO)
      "net.ipv4.tcp_fastopen" = 0;
      ## Bufferbloat mitigations
      # Requires >= 4.9 & kernel module
      "net.ipv4.tcp_congestion_control" = "bbr";
      # Requires >= 4.19
      "net.core.default_qdisc" = "cake";

      "net.ipv4.tcp_rmem" = "4096 87380 2500000";
      "net.ipv4.tcp_wmem" = "4096 65536 2500000";
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.core.somaxconn" = 4096;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.send_redirects" = 0;

      "net.ipv4.tcp_tw_recycle" = 0;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_no_metrics_save" = 1;
      "net.ipv4.tcp_sack" = 1;
      # "vm.overcommit_memory" = 1;
      "vm.swappiness" = 95;
      "vm.max_map_count" = 2147483642;
      "net.ipv4.tcp_ecn" = 1;
    };
  };
}
