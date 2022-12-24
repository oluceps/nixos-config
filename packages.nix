{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    unrar-wrapper
    
    lynx
    srm
    killall
    nethogs
    (callPackage ./modules/packs/clash-m { })
    fscrypt-experimental
    f2fs-tools
    xmrig
    nali
    dbus

    pkg-config
    compsize
    nur-pkgs.naiveproxy
    autossh
    restic
    socat
    miniserve
    any-nix-shell
    hardinfo
    mtr-gui
    qjournalctl
    editorconfig-checker
    #    (callPackage ./modules/packs/shadow-tls { })

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
    onefetch
    #snapper
    cachix
    android-tools
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

    mongodb-tools
    tcpdump

    pciutils
    b3sum
    usbutils
    ranger
    w3m

    exa

    bat

    mongodb

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
    clang-tools
    libclang
    wget
    nixos-option
    lua
    proxychains
    go
    binutils
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
    llvm
    clang
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
          # pylsp-mypy

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
          cryptography

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
        :map <C-j> 5j
        :map <C-k> 5k
        :map qq    :q!<cr>

      '';
    }
    )
  ];
}
