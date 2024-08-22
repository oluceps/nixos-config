{ pkgs, lib, ... }:
{
  environment.systemPackages =
    lib.flatten (
      lib.attrValues (
        with pkgs;
        {
          python = [
            (python311.withPackages (
              ps: with ps; [
                pandas
                requests
                absl-py
                tldextract
                bleak
                matplotlib
                clang
                pyyaml
              ]
            ))
          ];
          crypt = [
            minisign
            rage
            age-plugin-yubikey
            cryptsetup
            tpm2-tss
            tpm2-tools
            yubikey-manager
            monero-cli
            yubikey-personalization
          ];

          dev = [
            vscode.fhs
            nodejs_latest.pkgs.pnpm
            qemu-utils
            rustup
            linuxPackages_latest.perf
            gitoxide
            gitui
            nushell
            # radicle
            # friture

            pv
            devenv
            # gnome.dconf-editor

            [
              bpf-linker
              gdb
              gcc
              gnumake
              cmake
            ]
            lua
            delta
            go
            nix-tree
            kotlin
            inotify-tools
            tmux

            trunk
            cargo-expand
            wasmtime
            comma
            nix-update
          ];

          lang = [
            [
              editorconfig-checker
              kotlin-language-server
              sumneko-lua-language-server
              yaml-language-server
              tree-sitter
              stylua
              biome
              # black
            ]
            # languages related
            [
              zig
              lldb
              # haskell-language-server
              gopls
              cmake-language-server
              zls
              android-file-transfer
              nixpkgs-review
              shfmt
            ]
          ];
          # wine = [
          #   # bottles
          #   wineWowPackages.stable

          #   # support 32-bit only
          #   # wine

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

          de = with gnomeExtensions; [
            simple-net-speed
            paperwm
          ];

          virt = [
            # virt-manager
            virtiofsd
            runwin
            guix-run
            runbkworm
            bkworm
            arch-run
            # ubt-rv-run
            #opulr-a-run
            lunar-run
            virt-viewer
          ];
          fs = [
            gparted
            e2fsprogs
            fscrypt-experimental
            f2fs-tools
          ];

          cmd = [
            metasploit
            # linuxKernel.packages.linux_latest_libre.cpupower
            clean-home
            just
            typst
            cosmic-term
            acpi
            swww
            distrobox
            dmidecode
            nix-output-monitor

          ];
          info = [
            parallel-disk-usage # disk space info
            freshfetch
            htop
            onefetch
            hardinfo
            imgcat
            nix-index
            ccze
            unar
          ];
          bluetooth = [ bluetuith ];

          sound = [ pulseaudio ];

          display = [ cage ];

          cursor = [ graphite-cursors ];
        }
      )
    )
    ++ (with pkgs.nodePackages; [
      typescript-language-server
      node2nix
      markdownlint-cli2
      prettier
    ]);
}
