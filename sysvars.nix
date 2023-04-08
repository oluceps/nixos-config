{ user
, ...
}: {
  environment.sessionVariables = {
    NEOVIDE_MULTIGRID = "1";
    NEOVIDE_WM_CLASS = "1";
    AUTOSSH_DEBUG = "1";
    EDITOR = "hx";
    # NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    NODE_PATH = "~/.npm-packages/lib/node_modules";
    PATH = [
      # "\${XDG_BIN_HOME}"
      "/home/${user}/.npm-packages/bin"
      "/home/${user}/.pip/bin"
    ];
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    XDG_DATA_HOME = "\${HOME}/.local/share";
    # Steam needs this to find Proton-GE
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";

    NIX_CFLAGS_COMPILE = "--verbose";
    NIX_CFLAGS_LINK = "--verbose";
    NIX_LDFLAGS = "--verbose";
  };
}
