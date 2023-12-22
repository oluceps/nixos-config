{ pkgs, config, user, lib, ... }: {
  # Mobile device.

  system.stateVersion = "23.05"; # Did you read the comment?
  hardware.opengl.driSupport = true;
  # For 32 bit applications
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
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

  services =
    lib.mkMerge [
      {
        inherit ((import ../../services.nix { inherit pkgs lib config; }).services) dae;
      }
      {
        dae.enable = true;
        sing-box = {
          enable = false;
        };


        shadowsocks.instances = [{
          name = "kaambl-local";
          configFile = config.age.secrets.ss.path;
        }];
        hysteria.instances = [{
          name = "kaambl-local";
          configFile = config.age.secrets.hyst-us-cli.path;
        }];
        # juicity.instances = [{
        #   name = "kaambl-local";
        #   configFile = config.age.secrets.hyst-us-cli.path;
        # }];

        factorio = {
          enable = false;
          openFirewall = true;
          serverSettingsFile = config.age.secrets.factorio-server.path;
          serverAdminsFile = config.age.secrets.factorio-server.path;
          mods =
            [
              ((pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
                name = "helmod";
                version = "0.12.19";
                src = pkgs.fetchurl {
                  url = "https://dl-mod.factorio.com/files/89/c9e3dfbb99555ba24b085c3228a95fc7a9ad6c?secure=kuZjLfCXoc9awR6dgncRrQ,1702896059";
                  hash = "sha256-tUMZWQ8snt3y8WUruIN+skvo9M1V8ZhM7H9QNYkALYQ=";
                };
                dontUnpack = true;
                installPhase = ''
                  runHook preInstall
                  install -m 0644 $src -D $out/helmod_${finalAttrs.version}.zip
                  runHook postInstall
                '';
              })) // { deps = [ ]; })
            ];
        };



        gvfs.enable = false;
        blueman.enable = true;
        btrbk.enable = true;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
        sundial.enable = true;

        greetd = {
          enable = true;
          settings = rec {
            initial_session = {
              command =
                "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.writeShellScript "sway" ''
          export $(/run/current-system/systemd/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
          exec sway
        ''}";
              inherit user;
            };
            default_session = initial_session;
          };
        };

        # xserver = {
        #   videoDrivers = [ "amdgpu" ];
        #   enable = true;
        #   displayManager = {
        #     # sddm.enable = true;
        #     gdm = {
        #       enable = false;
        #     };

        #   };
        #   desktopManager = {
        #     # plasma5.enable = true;
        #     gnome.enable = false;
        #   };
        # };
      }
    ]
  ;





  # services.udev = {
  #   packages = with pkgs; [ gnome.gnome-settings-daemon ];
  # };

  # environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
  systemd = {
    enableEmergencyMode = true;
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

  };
  programs.dconf.enable = true;
  programs = {
    anime-game-launcher.enable = true; # Adds launcher and /etc/hosts rules
    anime-borb-launcher.enable = true;
    honkers-railway-launcher.enable = true;
    honkers-launcher.enable = true;
  };
  systemd.tmpfiles.rules = [
    # "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    "L+ /run/gdm/.config/monitors.xml - - - - ${pkgs.writeText "gdm-monitors.xml" ''
        <monitors version="2">
            <configuration>
                <logicalmonitor>
                    <x>0</x>
                    <y>0</y>
                    <scale>2</scale>
                    <primary>yes</primary>
                    <monitor>
                        <monitorspec>
                            <connector>eDP-1</connector>
                            <vendor>BOE</vendor>
                            <product>0x0893</product>
                            <serial>0x00000000</serial>
                        </monitorspec>
                        <mode>
                            <width>2160</width>
                            <height>1440</height>
                            <rate>60.001</rate>
                        </mode>
                    </monitor>
                </logicalmonitor>
            </configuration>
        </monitors>
    ''}"
  ];
}
