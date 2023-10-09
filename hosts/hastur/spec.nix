{ pkgs, config, user, ... }: {
  # This headless machine uses to perform heavy task.
  # Running database and web services.

  system.stateVersion = "22.11"; # Did you read the comment?

  hardware = {
    #   nvidia = {
    #     package = config.boot.kernelPackages.nvidiaPackages.latest;
    #     modesetting.enable = true;
    #     powerManagement.enable = false;
    #   };

    # opengl = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     rocm-opencl-icd
    #     rocm-opencl-runtime
    #   ];
    #   driSupport = true;
    #   driSupport32Bit = true;
    # };
  };

  systemd = {
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
  networking.firewall.allowedTCPPorts =
    [ 9000 9001 ] ++ [ config.services.photoprism.port ];

  xdg.portal.wlr.enable = true;

  programs.dconf.enable = true;

  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      enableTCPIP = true;
      port = 5432;
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust

        #type database DBuser origin-address auth-method
        # ipv4
        host  all      all     127.0.0.1/32   trust
        host  all      all     10.0.1.1/24   trust
        host  all      all     10.0.0.1/24   trust
        # ipv6
        host all       all     ::1/128        trust
      '';

    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    photoprism = {
      enable = true;
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
      enable = true;
      region = "ap-east-1";
      rootCredentialsFile = config.age.secrets.minio.path;
    };


    mysql = {
      enable = true;
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
  };
}
