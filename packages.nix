{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    q
    clang-tools_15
    rustup
    e2fsprogs
    gparted
    unar
    hyprpicker

    cmake
    llvmPackages_latest.clang
    # clang-tools
    runit
    onefetch
    lsd
    texlab
    tokei
    bottom

    virtiofsd
    edk2
    unrar-wrapper

    bpf-linker
    ghc
    pueue
    lynx
    srm
    killall
    nethogs
    (callPackage ./pkgs/clash-m { })
    fscrypt-experimental
    f2fs-tools
    xmrig
    nali
    dbus

    pkg-config
    compsize
    autossh
    restic
    socat
    miniserve
    any-nix-shell
    hardinfo
    mtr-gui
    qjournalctl
    editorconfig-checker

    #    nur-pkgs.shadow-tls
    nur-pkgs.sing-box
    # KVM
    virt-manager
    # common
    hexyl
    jq
    fx
    fd
    choose
    duf
    procs
    #    httpie
    dog


    arti
    # onefetch
    #snapper
    cachix
    qrencode
    wakelan
    netcat-gnu
    gdb


    # languages related
    nixpkgs-fmt
    zig
    lldb
    haskell-language-server
    gopls
    cmake-language-server
    zls
    android-file-transfer
    nixpkgs-review

    shfmt
    #    rustup
    broot
    pyright
    rnix-lsp
    kotlin-language-server
    sumneko-lua-language-server
    taplo-lsp
    taplo-cli
    yaml-language-server
    tree-sitter
    stylua
    black



    powertop

    zbar

    lazygit
    netcat
    bpftools

    inetutils
    imgcat

    tcpdump

    pciutils
    b3sum
    usbutils
    ranger
    w3m

    exa

    bat

    mtr
    openssl

    tor
    iperf3
    ethtool
    nixpkgs-fmt
    dig
    btrfs-progs
    wireguard-tools
    gnupg
    nftables
    wget
    nixos-option
    lua
    proxychains
    go
    libcap
    gnumake

    nodejs-18_x
    yarn
    unzip
    ripgrep
    bash
    wget
    git
    zip
    whois
    neofetch
    htop
    lsof
    tree
    gcc
    curl
    jdk
    coreutils
    nix-index

    dnsutils
    docker
    docker-compose

  ] ++
  [
    (
      python3.withPackages
        (p: with p;[
          wordcloud
          qrcode
          matplotlib
          pylsp-mypy

          fontforge

          pyzbar
          pymongo

          aiohttp
          loguru
          pillow
          dbus-python
          numpy
          redis
          requests
          uvloop

          fido2
          nrfutil
          tockloader
          intelhex
          colorama
          tqdm
          # cryptography

          pandas
          requests
          pyrogram
          tgcrypto
          JPype1
          toml
          pyyaml
          tockloader
          colorama
          six
          rich
          lxml
          sympy

          cffi
          # beautifulreport

        ])
    )
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
    ((vim_configurable.override { }).customize {
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
