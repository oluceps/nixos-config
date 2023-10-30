{ pkgs, config, user, ... }: {
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
    enable = true;
    swapDevices = 1;
    memoryPercent = 80;
    algorithm = "zstd";
  };

  services = {
    gvfs.enable = false;
    blueman.enable = true;
    # btrbk.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
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
  };





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
