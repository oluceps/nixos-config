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

  services.xserver = {
    videoDrivers = [ "amdgpu" ];
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  environment.systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
  services.udev = {
    packages = with pkgs; [ gnome.gnome-settings-daemon ];
    extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    '';
  };
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
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
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
