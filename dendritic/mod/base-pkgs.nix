{
  flake.modules.nixos.base-pkgs =
    {
      pkgs,
      lib,
      ...
    }:
    let
      p = with pkgs; {

        net = [
          # anti-censor
          [
            sing-box
            tor
            arti
            oniux
          ]

          [
            rustscan
            stun
            bandwhich
            iperf3
            dnsutils
            tcpdump
            netcat
            wget
            socat
            miniserve
            mtr
            q
            nali
            nethogs
            dig
            wireguard-tools
            # curlFull
            (curl.override {
              ldapSupport = true;
              gsaslSupport = true;
              rtmpSupport = true;
              pslSupport = true;
              websocketSupport = true;
              # echSupport = true;
            })
            xh
            # ngrep
            gping
            tcping-go
            # httping
            iftop
            # cilium-cli
          ]
        ];
        cmd = [
          eza
          fzf
          mcrcon

          smartmontools
          # attic
          ntfy-sh
          helix
          srm
          # onagre

          # common
          [
            killall
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
            lsof
            tree
            bat
          ]
          [
            ripgrep
            qrencode
            lazygit
            b3sum
            coreutils
            traceroute
            rsync
          ]
        ];

      };
    in
    {
      environment.systemPackages = lib.flatten (lib.attrValues p) ++ [
        ((pkgs.vim-full.override { }).customize {
          name = "vim";
          # Install plugins for example for syntax highlighting of nix files
          vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
            start = [
              vim-nix
              vim-lastplace
            ];
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
        })
      ];
    };
}
