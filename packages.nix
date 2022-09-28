{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    arti
    onefetch
    snapper
    cachix
    nixpkgs-fmt
    android-tools
    qrencode
    wakelan

    zig
    lldb
    haskell-language-server
    gopls
    cmake-language-server
    zls
    android-file-transfer
    nixpkgs-review
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
    clash

    bat

    shfmt
    broot
    rust-analyzer
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

    mongodb

    mtr
    openssl_1_1

    tor
    iperf3
    ethtool
    nixpkgs-fmt
    dig
    btrfs-progs
    jq
    wireguard-tools
    gnupg
    nftables
    openssl.dev
    clang-tools
    libclang
    wget
    nixos-option
    lua
    proxychains
    go
    binutils
    libcap
    home-manager
    gnumake
    rustup
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
    tmux
    dnsutils
    openssl
    docker
    docker-compose



  ] ++
  [
    (
      python3.withPackages
        (p: with p;[
          qrcode
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
        ])
    )
  ]
  ++
  (with pkgs.nodePackages; [
    vscode-json-languageserver
    typescript-language-server
    node2nix
    markdownlint-cli2
    prettier
  ]);
}
