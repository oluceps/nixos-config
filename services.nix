{ pkgs
, lib
, user
, config
, ...
}:

let
  whenHost = h: with config.networking; (hostName == h);
in
{
  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };


  systemd = {
    # package = pkgs.systemd.override {
    #   withResolved = false;
    # };

    # Given that our systems are headless, emergency mode is useless.
    # We prefer the system to attempt to continue booting so
    # that we can hopefully still access it remotely.
    enableEmergencyMode = false;

    # For more detail, see:
    #   https://0pointer.de/blog/projects/watchdog.html
    watchdog = {
      # systemd will send a signal to the hardware watchdog at half
      # the interval defined here, so every 10s.
      # If the hardware watchdog does not get a signal for 20s,
      # it will forcefully reboot the system.
      runtimeTime = "20s";
      # Forcefully reboot if the final stage of the reboot
      # hangs without progress for more than 30s.
      # For more info, see:
      #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
      rebootTime = "30s";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  # photoprism minio
  networking.firewall.allowedTCPPorts = [ 20800 9000 9001 ];
  services = {
    btrbk = {
      enable = true;
      config = ''
        ssh_identity /persist/keys/ssh_host_ed25519_key
        timestamp_format        long
        snapshot_preserve_min   18h
        snapshot_preserve       48h 
        volume /persist
          snapshot_dir .snapshots
          subvolume .
          snapshot_create onchange
      '';
    };
    fwupd.enable = true;
    # vault = { enable = true; extraConfig = "ui = true"; package = pkgs.vault-bin; };
    photoprism = {
      enable = whenHost "hastur";
      originalsPath = "/var/lib/private/photoprism/originals";
      address = "[::]";
      passwordFile = config.age.secrets.prism.path;
      settings = {
        PHOTOPRISM_ADMIN_USER = "${user}";
        PHOTOPRISM_DEFAULT_LOCALE = "en";
        PHOTOPRISM_DATABASE_NAME = "photoprism";
        PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
        PHOTOPRISM_DATABASE_USER = "photoprism";
        PHOTOPRISM_DATABASE_DRIVER = "mysql";
      };
      port = 20800;
    };
    minio = {
      enable = whenHost "hastur";
      region = "ap-east-1";
      rootCredentialsFile = config.age.secrets.minio.path;
    };

    dbus = {
      enable = true;
      implementation = "broker";
      apparmor = "enabled";
    };
    gvfs.enable = true;
    # github-runners = {
    #   runner1 = {
    #     enable = false;
    #     name = "nixos-0";
    #     tokenFile = config.age.secrets.gh-eu.path;
    #     url = "https://github.com/oluceps/eunomia-bpf";
    #   };
    # };
    # autossh.sessions = [
    #   {
    #     extraArguments = "-NTR 5002:127.0.0.1:22 az";
    #     monitoringPort = 20000;
    #     name = "az";
    #     inherit user;
    #   }
    # ];
    flatpak.enable = true;
    journald.extraConfig =
      ''
        SystemMaxUse=1G
      '';
    sundial = {
      enable = false;
      calendars = [ "Sun,Mon-Thu 23:18:00" "Fri,Sat 23:48:00" ];
      warnAt = [ "Sun,Mon-Thu 23:16:00" "Fri,Sat 23:46:00" ];
    };

    # HORRIBLE
    mongodb = {
      enable = false;
      package = pkgs.mongodb-6_0;
      enableAuth = true;
      initialRootPassword = "initial";
    };

    mysql = {
      enable = whenHost "hastur";
      package = pkgs.mariadb_1011;
      dataDir = "/var/lib/mysql";
      ensureDatabases = [ "photoprism" ];
      ensureUsers = [
        {
          name = "riro";
          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
        {
          name = "photoprism";
          ensurePermissions = {
            "photoprism.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command =
            "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.writeShellScript "sway" ''
          export $(/run/current-system/systemd/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
          exec sway
        ''}";
          user = "greeter";
        };

      };
    };

    udev = {

      packages = with pkgs;[
        android-udev-rules
        qmk-udev-rules
        yubikey-personalization
        libu2f-host
        via
        opensk-udev-rules
        nrf-udev-rules
      ];
    };

    gnome.gnome-keyring.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    hyst-az.enable = false;
    hyst-do.enable = true;

    # ss-tls cnt to router
    ss.enable = true;
    tuic.enable = false;
    naive.enable = false;

    clash =
      {
        enable =
          false;
      };

    sing-box.enable = true;
    rathole.enable = true;

    dae = {
      enable = true;
      txChecksumIpGeneric = false;
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/persist" "/nix" ];
    };
    pcscd.enable = true;

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = lib.mkForce false;
        PermitRootLogin = lib.mkForce "prohibit-password";
        UseDns = true;
        X11Forwarding = false;
      };
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
      extraConfig = ''
        ClientAliveInterval 60
        ClientAliveCountMax 720
      '';
    };

    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
    };

    resolved = {
      enable = false;
      dnssec = "false";
      llmnr = "true";
      extraConfig = ''
        DNS=223.6.6.6#dns.alidns.com
        FallbackDNS=
        DNSOverTLS=no
        # Cache=no
        DNSStubListener=yes
      '';
    };

    smartdns = {
      enable = false;
      settings = {
        cache-size = 4096;
        server-tls = [ "223.6.6.6:853" "1.0.0.1:853" ];
        server-https = [ "https://dns.alidns.com/dns-query" ];
        prefetch-domain = true;
        speed-check-mode = "ping,tcp:80";
      };
    };
    mosdns = {
      enable = true;
      config = {
        log = { level = "debug"; production = false; };
        plugins = [
          {
            args = {
              files = [ "${pkgs.acc-cn}/accelerated-domains.china.txt" ];
            };
            tag = "direct_domain";
            type = "domain_set";
          }
          {
            args = {
              files = [ "${pkgs.all-cn}/all_cn.txt" ];
            };
            tag = "direct_ip";
            type = "ip_set";
          }
          {
            args = {
              dump_file = "./cache.dump";
              lazy_cache_ttl = 86400;
              size = 65536;
            };
            tag = "cache";
            type = "cache";
          }
          {
            args = {
              concurrent = 2;
              upstreams = [
                { addr = "tls://8.8.4.4:853"; idle_timeout = 86400; enable_pipeline = true; }
                { addr = "tls://1.0.0.1:853"; idle_timeout = 86400; enable_pipeline = true; }
              ];
            };
            tag = "remote_forward";
            type = "forward";
          }
          {
            args = {
              concurrent = 2;
              upstreams = [
                { addr = "https://223.6.6.6/dns-query"; idle_timeout = 86400; }
                { addr = "https://120.53.53.53/dns-query"; idle_timeout = 86400; }
              ];
            };
            tag = "local_forward";
            type = "forward";
          }
          {
            args = [
              { exec = "ttl 600-3600"; }
              { exec = "accept"; }
            ];
            tag = "ttl_sequence";
            type = "sequence";
          }
          {
            args = [
              { exec = "query_summary local_forward"; }
              { exec = "$local_forward"; }
              { exec = "goto ttl_sequence"; }
            ];
            tag = "local_sequence";
            type = "sequence";
          }
          {
            args = [
              { exec = "query_summary remote_forward"; }
              { exec = "$remote_forward"; }
              { exec = "goto local_sequence"; matches = "resp_ip $direct_ip"; }
              { exec = "goto ttl_sequence"; }
            ];
            tag = "remote_sequence";
            type = "sequence";
          }
          {
            args = {
              always_standby = false;
              primary = "remote_sequence";
              secondary = "local_sequence";
              threshold = 500;
            };
            tag = "final";
            type = "fallback";
          }
          {
            args = [
              { exec = "prefer_ipv4"; }
              { exec = "$cache"; }
              { exec = "accept"; matches = "has_resp"; }
              { exec = "goto local_sequence"; matches = "qname $direct_domain"; }
              { exec = "$final"; }
            ];
            tag = "main_sequence";
            type = "sequence";
          }
          {
            args = {
              entry = "main_sequence";
              listen = ":53";
            };
            tag = "udp_server";
            type = "udp_server";
          }
        ];
      };
    };
  };
  networking.resolvconf.package = lib.mkForce
    pkgs.openresolv;

  programs = {
    ssh.startAgent = false;
    proxychains = {
      enable = true;
      package = pkgs.proxychains-ng;

      chain = {
        type = "strict";
      };
      proxies = {
        socks-hyst-az = {
          enable = false;
          type = "socks5";
          host = "127.0.0.1";
          port = 1083;
        };
        socks-hyst-do = {
          enable = true;
          type = "socks5";
          host = "127.0.0.1";
          port = 1085;
        };
      };
    };
  };
}
