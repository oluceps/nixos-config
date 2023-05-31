{ pkgs, lib, ... }:
let
  p = with pkgs; {
    dev = lib.flatten [
      [ pinentry-curses swagger-codegen3 bump2version openssl linuxPackages_latest.perf cloud-utils ]
      [ bpf-linker pkg-config gdb gcc gnumake cmake clang-tools_15 llvmPackages_latest.clang ]
      [ openocd ]
      lua
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
    ];
    # ++ [
    #   (fenix.complete.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ])
    #   fenix.targets.wasm32-unknown-unknown.latest.rust-std

    #   #"targets.wasm32-unknown-unknown.latest.rust-std"
    # ];
    db = [ mongosh ];

    web = [ hugo ];

    crypt = [ rage age-plugin-yubikey yubikey-manager yubikey-manager-qt gnupg ];

    net = lib.flatten [
      # anti-censor
      [ nur-pkgs.dae sing-box rathole tor arti ]

      [ iperf3 i2p ethtool dnsutils autossh tcpdump netcat dog wget mtr-gui socat miniserve mtr wakelan netcat-gnu q nali lynx nethogs restic w3m whois dig wireguard-tools curl ngrep gping knot-dns ]
    ];

    virt = [
      # virt-manager
      virtiofsd
      windows-run
      ubt-rv-run
    ];
    fs = [ gparted e2fsprogs fscrypt-experimental f2fs-tools compsize ];

    cmd = lib.flatten [
      # (ragenix.override { plugins = [ age-plugin-yubikey ]; })
      helix
      srm
      onagre
      libsixel
      ouch

      # common
      [ killall hexyl jq fx bottom lsd fd choose duf tokei procs exa lsof tree bat ]
      [ broot powertop ranger ripgrep qrencode lazygit b3sum unzip zip coreutils bpftools inetutils pciutils usbutils pinentry ]
    ];

    lang = lib.flatten [
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

    info = [ neofetch htop onefetch hardinfo qjournalctl hyprpicker imgcat nix-index ccze ];

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
