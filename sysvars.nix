{ config
, pkgs
, user
, ...
}: {
  environment.sessionVariables = rec {
    NEOVIDE_MULTIGRID = "1";
    NEOVIDE_WM_CLASS = "1";
    EDITOR = "hx";
    NIXOS_OZONE_WL = "1";

    MOZ_ENABLE_WAYLAND = "1";

    NODE_PATH = "~/.npm-packages/lib/node_modules";
    PATH = [
      "\${XDG_BIN_HOME}"
      "/home/${user}/.npm-packages/bin"
    ];
  };
}
