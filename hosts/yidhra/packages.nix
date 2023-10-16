{ pkgs, lib, ... }:
let
  p = with pkgs; {

    # ++ [
    #   (fenix.complete.withComponents [ "cargo" "clippy" "rust-src" "rustc" "rustfmt" ])
    #   fenix.targets.wasm32-unknown-unknown.latest.rust-std

    #   #"targets.wasm32-unknown-unknown.latest.rust-std"
    # ];

    crypt = [ minisign rage age-plugin-yubikey yubico-piv-tool yubikey-manager yubikey-manager-qt cryptsetup ];

    net = [
      # anti-censor
      [ sing-box rathole tor arti nur-pkgs.tuic ]

      [ iperf3 i2p ethtool dnsutils autossh tcpdump netcat dog wget mtr-gui socat miniserve mtr wakelan q nali lynx nethogs restic w3m whois dig wireguard-tools curlHTTP3 xh ngrep gping knot-dns tcping-go httping ]
    ];
    # graph = [
    #   vulkan-validation-layers
    # ];

    cmd = [
      tmux
      clean-home
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

    info = [ freshfetch htop bottom onefetch hardinfo qjournalctl hyprpicker imgcat nix-index ccze ];

  };
in
{
  environment.systemPackages = lib.flatten (lib.attrValues p)
    ++ (with pkgs; [ unar texlab edk2 xmrig ])
    ++
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
