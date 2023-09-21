{ inputs, pkgs, lib, ... }:
let
  p = with pkgs; {
    dev = [
      yubikey-personalization
      racket
      resign
      pv
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
      awscli2
      trunk
      cargo-expand
      wasmer
      wasmtime
      comma
      nix-update
      nodejs_latest.pkgs.pnpm
    ];
    # ++ [
    #   (fenix.complete.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ])
    #   fenix.targets.wasm32-unknown-unknown.latest.rust-std

    #   #"targets.wasm32-unknown-unknown.latest.rust-std"
    # ];
    db = [ mongosh ];

    web = [ hugo ];

    crypt = [ rage age-plugin-yubikey yubico-piv-tool yubikey-manager yubikey-manager-qt cryptsetup ];

    net = [
      # anti-censor
      [ sing-box rathole tor arti nur-pkgs.tuic ]

      [ iperf3 i2p ethtool dnsutils autossh tcpdump netcat dog wget mtr-gui socat miniserve mtr wakelan q nali lynx nethogs restic w3m whois dig wireguard-tools curlHTTP3 xh ngrep gping knot-dns tcping-go httping ]
    ];
    # graph = [
    #   vulkan-validation-layers
    # ];

    de = with gnomeExtensions;[ simple-net-speed blur-my-shell ];

    virt = [
      # virt-manager
      virtiofsd
      runwin
      runbkworm
      # ubt-rv-run
      opulr-a-run
      lunar-run
      virt-viewer
    ];
    fs = [ gparted e2fsprogs fscrypt-experimental f2fs-tools compsize ];

    cmd = [
      # (ragenix.override { plugins = [ age-plugin-yubikey ]; })
      clean-home
      typst
      helix
      srm
      onagre
      libsixel
      ouch
      nix-output-monitor

      # common
      [ killall hexyl jq fx bottom lsd fd choose duf tokei procs lsof tree bat ]
      [ broot powertop ranger ripgrep qrencode lazygit b3sum unzip zip coreutils inetutils pciutils usbutils pinentry ]
    ];
    # ripgrep-all 
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

    info = [ freshfetch htop bottom onefetch hardinfo qjournalctl hyprpicker imgcat nix-index ccze ];

  };
in
{
  environment.systemPackages = lib.flatten (lib.attrValues p)
    ++ (with pkgs; [ unar texlab edk2 xmrig docker-compose ]) ++
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


            # wordcloud
            # qrcode
            # matplotlib
            # pylsp-mypy
            # pip

            # fontforge

            # pyzbar
            # pymongo

            # # aiohttp
            # loguru
            # pillow
            # dbus-python
            # numpy
            # redis
            # requests
            # uvloop

            # fido2
            # nrfutil
            # tockloader
            # intelhex
            # colorama
            # tqdm
            # # cryptography

            # pandas
            # requests
            # pyrogram
            # tgcrypto
            # JPype1
            # toml
            # pyyaml
            # tockloader
            # colorama
            # six
            # rich
            # lxml
            # sympy

            # cffi
            # beautifulreport

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
    ]) ++
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
    ];
}
