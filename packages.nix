{ pkgs, lib, ... }:
let
  p = with pkgs; {
    dev = [
      pinentry-curses
      swagger-codegen3
      bump2version
      openssl
      linuxPackages_latest.perf
      cloud-utils
      lua
      nodejs-18_x
      yarn
      rustup
      bpf-linker
      pkg-config
      gdb
      gcc
      gnumake
      cmake
      clang-tools_15
      llvmPackages_latest.clang
    ];
    net = [
      rathole
      nftables
      tor
      iperf3
      i2p
      ethtool
      dnsutils
      autossh
      tcpdump
      nur-pkgs.sing-box
      netcat
      dog
      wget
      mtr-gui
      socat
      arti
      miniserve
      mtr
      wakelan
      netcat-gnu
      q
      nali
      lynx
      nethogs
      restic
      w3m
      whois
      dig
      wireguard-tools
      curl
    ];

    virt = [ virt-manager virtiofsd ];
    fs = [ gparted e2fsprogs fscrypt-experimental f2fs-tools compsize ];

    cmd = [
      srm

      killall
      # common
      hexyl
      jq
      fx
      bottom
      lsd
      fd
      choose
      duf
      tokei
      procs

      exa

      lsof
      tree
      bat

      broot
      powertop
      ranger

      ripgrep

      qrencode
      lazygit
      b3sum
      unzip
      zip
      coreutils

      bpftools
      inetutils
      pciutils
      usbutils
      pinentry
    ];

    lang = [

      editorconfig-checker
      pyright
      kotlin-language-server
      sumneko-lua-language-server
      taplo-lsp
      taplo-cli
      yaml-language-server
      tree-sitter
      stylua
      black

      # languages related
      zig
      lldb
      haskell-language-server
      gopls
      cmake-language-server
      zls
      android-file-transfer
      nixpkgs-review
      shfmt
    ];

    info = [ neofetch htop onefetch hardinfo qjournalctl hyprpicker imgcat nix-index ];

  };
in
{
  environment.systemPackages = lib.flatten (lib.attrValues p)
    ++ (with pkgs; [ unar texlab edk2 xmrig docker-compose ]) ++
    [
      (with pkgs; (
        python3.withPackages
          (p: with p;[
            wordcloud
            qrcode
            matplotlib
            pylsp-mypy
            pip

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
