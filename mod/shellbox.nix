{
  inputs,
  ...
}:
let
  # Ports inside the container (adjacent pair).
  sshPort = 2222;
  sparePort = 2223;

  # Ports on the host (adjacent pair), forwarded to the container by
  # systemd-socket-proxyd, same pattern as mod/vms/sep.nix.
  hostSshPort = 22022;
  hostSparePort = 22023;
in
{
  flake.modules.nixos.shellbox =
    {
      config,
      pkgs,
      ...
    }:
    let
      flyline = inputs.flyline.packages.${pkgs.stdenv.hostPlatform.system}.flyline;

      # Everything the container shell can use. The alpline image itself stays
      # untouched: /nix/store is bind-mounted read-only, so these run inside it.
      tools = pkgs.buildEnv {
        name = "shellbox-tools";
        paths = with pkgs; [
          # shell UX
          bashInteractive
          bash-completion
          coreutils
          findutils
          gnugrep
          gnused
          gawk
          diffutils
          file
          less
          tree
          which
          procps
          psmisc
          htop
          tmux
          vim
          nano
          strace
          lsof
          # archives / transfer
          curl
          wget
          rsync
          git
          unzip
          xz
          zstd
          gzip
          # data
          jq
          yq-go
          ripgrep
          fd
          fzf
          bat
          # networking toolbox
          openssh
          socat
          netcat-openbsd
          nmap
          tcpdump
          ngrep
          mtr
          traceroute
          iputils
          inetutils
          iproute2
          nettools
          ethtool
          iperf3
          dnsutils
          whois
          conntrack-tools
          nftables
          iptables
          openssl
        ];
        pathsToLink = [
          "/bin"
          "/sbin"
        ];
        ignoreCollisions = true;
      };

      # ---------------------------------------------------------------- files
      authorizedKeys = pkgs.writeTextDir "authorized_keys.d/root" ''
        sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH+HwSzDbhJOIs8cMuUaCsvwqfla4GY6EuD1yGuNkX6QAAAADnNzaDoxNjg5NTQzMzc1
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDcYqby4TnhKV6xGyuZUtxOmTtXjKYp8r+uCxbGph65
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlk4fFt1HfVenQFTyGgxHfxqPB8spVtZqzBC5R2gYNg ed-login-250928
        sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMhKqC4VMo5VOTKvdYA2vTqhNOTkyCqxifhcuAvbXJSNAAAAE3NzaDoxNzg0NzgzODMzLWdpZnQ= ssh:1784783833-gift
      '';

      sshdConfig = pkgs.writeText "shellbox-sshd_config" ''
        Port ${toString sshPort}
        AddressFamily any
        ListenAddress 0.0.0.0

        HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key
        HostKey /etc/ssh/hostkeys/ssh_host_rsa_key

        # key-only auth, no PAM, no passwd/shadow lookups beyond getpwnam
        PermitRootLogin prohibit-password
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        ChallengeResponseAuthentication no
        PubkeyAuthentication yes
        UsePAM no
        AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u
        AllowUsers root
        # tools are not in the alpine PATH, put them in every session
        SetEnv PATH=${tools}/bin

        StrictModes no
        UseDNS no
        PrintMotd no
        PrintLastLog no
        X11Forwarding no
        AllowTcpForwarding yes
        GatewayPorts no
        ClientAliveInterval 60
        ClientAliveCountMax 720

        Subsystem sftp internal-sftp
      '';

      passwd = pkgs.writeText "shellbox-passwd" ''
        root:x:0:0:root:/root:${pkgs.bashInteractive}/bin/bash
        sshd:x:74:74:sshd:/var/empty:${pkgs.bashInteractive}/bin/bash
        nobody:x:65534:65534:nobody:/var/empty:/sbin/nologin
      '';

      group = pkgs.writeText "shellbox-group" ''
        root:x:0:
        sshd:x:74:
        nobody:x:65534:
      '';

      profile = pkgs.writeText "shellbox-profile" ''
        export PATH=${tools}/bin
        export LANG=C.UTF-8
        : "''${TERM:=xterm-256color}"
        export TERM
        case $- in
          *i*) . /etc/bashrc ;;
        esac
      '';

      bashrc = pkgs.writeText "shellbox-bashrc" ''
        case $- in
          *i*) ;;
          *) return 0 ;;
        esac

        HISTFILE=/root/.bash_history
        HISTSIZE=100000
        HISTFILESIZE=100000
        shopt -s histappend checkwinsize
        shopt -s cdspell dirspell globstar

        PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

        alias ls='ls --color=auto'
        alias grep='grep --color=auto'
        alias ip='ip -color=auto'

        if [ -f ${pkgs.bash-completion}/share/bash-completion/bash_completion ]; then
          . ${pkgs.bash-completion}/share/bash-completion/bash_completion
        fi

        bind 'set completion-ignore-case on' 2>/dev/null
        bind 'set show-all-if-ambiguous on' 2>/dev/null

        # flyline replaces bash's readline line editor. It is a loadable builtin,
        # so it must match the bash above (same nixpkgs -> same bash).
        enable -f ${flyline}/lib/libflyline.so flyline
      '';

      rootBashrc = pkgs.writeText "shellbox-root-bashrc" ''
        . /etc/bashrc
      '';

      rootBashProfile = pkgs.writeText "shellbox-root-bash_profile" ''
        . /etc/profile
      '';

      entrypoint = pkgs.writeTextFile {
        name = "shellbox-init";
        executable = true;
        text = ''
          #!${pkgs.bashInteractive}/bin/bash
          set -euo pipefail
          export PATH=${tools}/bin

          mkdir -p /run/sshd /var/empty /etc/ssh/hostkeys
          chmod 0755 /run/sshd /var/empty
          chown 0:0 /var/empty

          # Host keys live in a podman volume, generate them on first boot.
          for t in ed25519 rsa; do
            key=/etc/ssh/hostkeys/ssh_host_''${t}_key
            if [ ! -s "$key" ]; then
              ssh-keygen -q -t "$t" -N "" -C "shellbox" -f "$key"
            fi
          done

          exec ${pkgs.openssh}/bin/sshd -D -e -f /etc/ssh/shellbox_sshd_config
        '';
      };

      healthcheck = pkgs.writeTextFile {
        name = "shellbox-healthcheck";
        executable = true;
        text = ''
          #!${pkgs.bashInteractive}/bin/bash
          exec 3<>/dev/tcp/127.0.0.1/${toString sshPort}
        '';
      };
    in
    {
      users = {
        groups.shellbox = { };
        users.shellbox = {
          isSystemUser = true;
          group = "shellbox";
          home = "/var/lib/shellbox";
          linger = true;
          createHome = true;
          uid = 986;
          autoSubUidGidRange = true;
        };
      };

      # linger-users.service only orders itself after systemd-logind, while
      # userborn.service is restarted in the same switch transaction. On a switch
      # that introduces a new user the two race, loginctl then dies with
      # "Failed to look up user shellbox: No such process" and the unit
      # start-limit-hits. Force userborn to run first.
      systemd.services.linger-users = {
        wants = [ "userborn.service" ];
        after = [
          "userborn.service"
          "systemd-sysusers.service"
        ];
      };

      # ----------------------------------------------------------------- rootless container
      virtualisation.oci-containers = {
        backend = "podman";
        containers.shellbox = {
          image = "docker.io/library/alpine:3.22";
          hostname = "shellbox";
          entrypoint = "/init";
          podman = {
            user = "shellbox";
            sdnotify = "healthy";
          };
          ports = [
            "127.0.0.1:${toString hostSshPort}:${toString sshPort}"
            "127.0.0.1:${toString hostSparePort}:${toString sparePort}"
          ];
          volumes = [
            # alpine image + nix store: no image rebuild needed for tools
            "/nix/store:/nix/store:ro"
            "${entrypoint}:/init:ro"
            "${sshdConfig}:/etc/ssh/shellbox_sshd_config:ro"
            "${authorizedKeys}:/etc/ssh/authorized_keys.d:ro"
            "${passwd}:/etc/passwd:ro"
            "${group}:/etc/group:ro"
            "${profile}:/etc/profile:ro"
            "${bashrc}:/etc/bashrc:ro"
            "${rootBashrc}:/root/.bashrc:ro"
            "${rootBashProfile}:/root/.bash_profile:ro"
            # ssh host keys survive container replacement
            "shellbox-ssh-hostkeys:/etc/ssh/hostkeys:rw"
          ];
          extraOptions = [
            "--sysctl=net.ipv4.ip_unprivileged_port_start=0"
            "--cap-add=NET_RAW"
            "--cap-add=NET_ADMIN"
            "--health-cmd=${healthcheck}"
            "--health-interval=30s"
            "--health-timeout=5s"
            "--health-start-period=10s"
            "--health-retries=3"
          ];
        };
      };

      # A container that comes up before its user manager exists (first
      # activation) should keep retrying instead of hitting the start limit.
      systemd.services.podman-shellbox = {
        startLimitIntervalSec = 0;
        serviceConfig.RestartSec = "5s";
      };

      # ------------------------------------------------- host side exposure
      # Container ports are published on loopback only; these sockets expose
      # them on [::] (both families) like mod/vms/sep.nix does.
      systemd.sockets.shellbox-ssh = {
        description = "Socket for shellbox SSH";
        wantedBy = [ "sockets.target" ];
        listenStreams = [ "[::]:${toString hostSshPort}" ];
        socketConfig = {
          Accept = false;
          BindIPv6Only = "both";
          FreeBind = true;
        };
      };

      systemd.services.shellbox-ssh = {
        description = "Forward :${toString hostSshPort} to the shellbox container";
        serviceConfig = {
          ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString hostSshPort}";
          DynamicUser = true;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };

      # Free TCP port for whatever you run inside the container on 0.0.0.0:2223.
      systemd.sockets.shellbox-tcp = {
        description = "Socket for shellbox spare TCP port";
        wantedBy = [ "sockets.target" ];
        listenStreams = [ "[::]:${toString hostSparePort}" ];
        socketConfig = {
          Accept = false;
          BindIPv6Only = "both";
          FreeBind = true;
        };
      };

      systemd.services.shellbox-tcp = {
        description = "Forward :${toString hostSparePort} to the shellbox container";
        serviceConfig = {
          ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString hostSparePort}";
          DynamicUser = true;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };

      networking.firewall.allowedTCPPorts = [
        hostSshPort
        hostSparePort
      ];
    };
}
