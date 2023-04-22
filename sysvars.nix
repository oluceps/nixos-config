{ user
, ...
}: {
  environment.sessionVariables = {
    # SYSTEMD_LOG_LEVEL="debug";
    EDITOR = "hx";
    # NIXOS_OZONE_WL = "1";
    # Steam needs this to find Proton-GE
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";

    NIX_CFLAGS_COMPILE = "--verbose";
    NIX_CFLAGS_LINK = "--verbose";
    NIX_LDFLAGS = "--verbose";
  };
}
