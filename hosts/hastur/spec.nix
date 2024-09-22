{
  pkgs,
  config,
  lib,
  ...
}:
{
  # This headless machine uses to perform heavy task.
  # Running database and web services.

  system.stateVersion = "22.11"; # Did you read the comment?
  users.mutableUsers = false;
  system.etc.overlay.mutable = false;
  # system.forbiddenDependenciesRegexes = [ "perl" ];
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
  '';

  zramSwap = {
    enable = false;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };
  programs.fish.loginShellInit = ''
    ${pkgs.openssh}/bin/ssh-add ${config.age.secrets.id.path}
  '';
  systemd = {
    enableEmergencyMode = false;
    watchdog = {
      runtimeTime = "20s";
      rebootTime = "30s";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  # photoprism minio
  networking.firewall.allowedTCPPorts = [
    9000
    9001
    6622
  ] ++ [ config.services.photoprism.port ];

  services.smartd.notifications.systembus-notify.enable = true;
  repack = {
    openssh.enable = true;
    fail2ban.enable = true;
    dae.enable = true;
    scrutiny.enable = true;
    ddns-go.enable = true;
    # atticd.enable = true;
    atuin.enable = true;
    postgresql.enable = true;
    # photoprism.enable = true;
    mysql.enable = true;
    prometheus.enable = true;
    vaultwarden.enable = true;
    matrix-conduit.enable = true;
    # coredns.enable = true;
    misskey.enable = true;
    dnsproxy.enable = true;
    srs.enable = true;
    grafana.enable = true;
    meilisearch.enable = true;
    radicle.enable = true;
  };
  services = {
    # ktistec.enable = true;
    # radicle.enable = true;
    metrics.enable = true;
    fwupd.enable = true;
    harmonia = {
      enable = true;
      signKeyPaths = [ config.age.secrets.harmonia.path ];
    };
    realm = {
      enable = false;
      settings = {
        log.level = "warn";
        network = {
          no_tcp = false;
          use_udp = true;
        };
        endpoints = [
          {
            listen = "[::]:2222";
            remote = "127.0.0.1:3001";
          }
        ];
      };
    };

    # xserver.videoDrivers = [ "nvidia" ];

    # xserver.enable = true;
    # xserver.displayManager.gdm.enable = true;
    # xserver.desktopManager.gnome.enable = true;

    # nextchat.enable = true;

    snapy.instances = [
      {
        name = "persist";
        source = "/persist";
        keep = "2day";
        timerConfig.onCalendar = "*:0/10";
      }
      {
        name = "var";
        source = "/var";
        keep = "7day";
        timerConfig.onCalendar = "daily";
      }
    ];

    tailscale = {
      enable = false;
      openFirewall = true;
    };

    sing-box.enable = true;
    restic = {
      backups = {
        # solid = {
        #   passwordFile = config.age.secrets.wg.path;
        #   repositoryFile = config.age.secrets.restic-repo.path;
        #   environmentFile = config.age.secrets.restic-envs.path;
        #   paths = [
        #     "/persist"
        #     "/var"
        #   ];
        #   extraBackupArgs = [
        #     "--one-file-system"
        #     "--exclude-caches"
        #     "--no-scan"
        #     "--retry-lock 2h"
        #   ];
        #   timerConfig = {
        #     OnCalendar = "daily";
        #     RandomizedDelaySec = "4h";
        #     FixedRandomDelay = true;
        #     Persistent = true;
        #   };
        # };
        critic = {
          #### CLOUDFLARE R2 but connectivity bad
          #   passwordFile = config.age.secrets.wg.path;
          #   repositoryFile = config.age.secrets.restic-repo-crit.path;
          #   environmentFile = config.age.secrets.restic-envs-crit.path;
          passwordFile = config.age.secrets.wg.path;
          repository = "s3:http://10.0.1.3:3900/crit";
          environmentFile = config.age.secrets.restic-envs-dc3.path;
          ####
          paths = [
            "/var/.snapshots/latest/lib/backup"
            "/var/.snapshots/latest/lib/private/matrix-conduit"
          ];
          extraBackupArgs = [
            "--exclude-caches"
            "--no-scan"
            "--retry-lock 2h"
          ];
          pruneOpts = [ "--keep-daily 3" ];
          timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "4h";
            FixedRandomDelay = true;
            Persistent = true;
          };
        };
      };
    };
    hysteria.instances = [
      {
        name = "nodens";
        configFile = config.age.secrets.hyst-us-cli.path;
      }
      {
        name = "abhoth";
        configFile = config.age.secrets.hyst-la-cli.path;
      }
    ];

    shadowsocks.instances = [
      {
        name = "rha";
        configFile = config.age.secrets.ss-az.path;
        serve = {
          enable = true;
          port = 6059;
        };
      }
    ];

    gvfs.enable = false;

    postgresqlBackup = {
      enable = true;
      location = "/var/lib/backup/postgresql";
      compression = "zstd";
      startAt = "*-*-* 04:00:00";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      # pulse.enable = true;
      # jack.enable = true;
    };

    minio = {
      enable = true;
      region = "ap-east-1";
      rootCredentialsFile = config.age.secrets.minio.path;
    };
  };
}
