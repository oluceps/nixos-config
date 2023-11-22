{ config, pkgs, lib, data, ... }:
let
  p = with pkgs; {

    crypt = [ minisign rage age-plugin-yubikey yubikey-manager yubikey-manager-qt cryptsetup ];

    net = [
      # anti-censor
      [ sing-box rathole tor arti nur-pkgs.tuic ]

      [ bandwhich fscan iperf3 i2p ethtool dnsutils autossh tcpdump netcat dog wget mtr-gui socat miniserve mtr wakelan q nali lynx nethogs restic w3m whois dig wireguard-tools curlHTTP3 xh ngrep gping knot-dns tcping-go httping ]
    ];
    # graph = [
    #   vulkan-validation-layers
    # ];

    cmd = [
      # (ragenix.override { plugins = [ age-plugin-yubikey ]; })
      linuxKernel.packages.linux_latest_libre.cpupower
      clean-home
      just
      typst
      helix
      srm
      onagre
      libsixel
      ouch
      nix-output-monitor
      linuxKernel.packages.linux_latest_libre.cpupower

      kitty

      # common
      [ killall hexyl jq fx bottom lsd fd choose duf tokei procs lsof tree bat ]
      [ broot powertop ranger ripgrep qrencode lazygit b3sum unzip zip coreutils inetutils pciutils usbutils pinentry ]
    ];
    # ripgrep-all 


    info = [ freshfetch htop bottom onefetch hardinfo qjournalctl hyprpicker imgcat nix-index ccze ];

  };

  e = with pkgs;{
    lang = [
      [
        editorconfig-checker
        kotlin-language-server
        sumneko-lua-language-server
        yaml-language-server
        tree-sitter
        stylua
        # black
      ]
      # languages related
      [ zig lldb haskell-language-server gopls cmake-language-server zls android-file-transfer nixpkgs-review shfmt ]
    ];

    dev = [
      friture
      qemu-utils
      yubikey-personalization
      racket
      resign
      pv
      devenv
      gnome.dconf-editor
      [ pinentry-curses swagger-codegen3 bump2version openssl linuxPackages_latest.perf cloud-utils ]
      [ bpf-linker gdb gcc gnumake cmake ] # clang-tools_15 llvmPackages_latest.clang ]
      # [ openocd ]
      lua
      delta
      # nodejs-18_x
      switch-mute
      yarn
      go
      nix-tree
      kotlin
      jre17_minimal
      inotify-tools
      rustup
      minio-client
      tmux
      awscli2
      trunk
      cargo-expand
      wasmer
      wasmtime
      comma
      nix-update
      nodejs_latest.pkgs.pnpm
    ];

    # wine = [
    #   # ...

    #   # support both 32- and 64-bit applications
    #   wineWowPackages.stable

    #   # support 32-bit only
    #   wine

    #   # support 64-bit only
    #   (wine.override { wineBuild = "wine64"; })

    #   # wine-staging (version with experimental features)
    #   wineWowPackages.staging

    #   # winetricks (all versions)
    #   winetricks

    #   # native wayland support (unstable)
    #   wineWowPackages.waylandFull
    # ];

    db = [ mongosh ];

    web = [ hugo ];

    de = with gnomeExtensions;[ simple-net-speed blur-my-shell ];

    virt = [
      # virt-manager
      virtiofsd
      runwin
      runbkworm
      bkworm
      arch-run
      # ubt-rv-run
      opulr-a-run
      lunar-run
      virt-viewer
    ];
    fs = [ gparted e2fsprogs fscrypt-experimental f2fs-tools compsize ];

    bluetooth = [ bluetuith ];

  };
in
{
  environment.systemPackages = lib.flatten (lib.attrValues p)
    ++ (with pkgs; [ unar texlab edk2 xmrig docker-compose ]) ++
    [
      ((pkgs.vim_configurable.override { }).customize {
        name = "vim";
        # Install plugins for example for syntax highlighting of nix files
        vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
          start = [ vim-nix vim-lastplace ];
          opt = [ ];
        };
        vimrcConfig.customRC = ''
          " your custom vimrc
          set nocompatible
          set backspace=indent,eol,start
          " Turn on syntax highlighting by default
          syntax on
        
          :let mapleader = " "
          :map <leader>s :w<cr>
          :map <leader>q :q<cr>
          :map <C-j> 5j
          :map <C-k> 5k
        '';
      }
      )
    ] ++
    (if (!(lib.elem config.networking.hostName (data.withoutHeads))) then
      (lib.flatten
        (lib.attrValues e)) ++
      [
        (with pkgs; (
          python3.withPackages
            (p: with p;[
              torch
              fire
              sentencepiece
              gensim
              numpy
              tqdm

              python-lsp-server
              mkdocs
              # mkdocs-static-i18n
              mkdocs-material
            ])
        ))
      ]
      ++
      (with pkgs.nodePackages; [
        vscode-json-languageserver
        typescript-language-server
        vscode-css-languageserver-bin
        node2nix
        markdownlint-cli2
        prettier
      ]) else [ ]
    )
  ;
}

  
