inputs:
let system = "x86_64-linux"; in [
  (final: prev:
    prev.lib.genAttrs
      [
        "hyprland"
        "hyprpicker"
        "clash-meta"
        "nil"
        "ragenix"
        "prismlauncher"
        "resign"
        "anyrun"
        "typst-lsp"
        "devenv"
      ]
      (n: inputs.${n}.packages.${system}.default)
    # //
    # GUI applications overlay. for stability
    # prev.lib.genAttrs [ "hyprland" ] (n: (import inputs.nixpkgs-gui { inherit system; }).${n})

    //
    {
      # lazygit =
      #   (import inputs.nixpkgs-gui
      #     {
      #       inherit system;
      #     }).lazygit;
      inherit ((import inputs.nixpkgs-master { inherit system; })) monaspace;

      # inputs.hyprland.packages.${system}.default;
      inherit ((import inputs.nixpkgs-rebuild { inherit system; })) nixos-rebuild;
      helix = inputs.helix.packages.${system}.default.override {
        includeGrammarIf = grammar:
          prev.lib.any
            (name: grammar.name == name)
            [
              "toml"
              "rust"
              "nix"
              "lua"
              "make"
              "protobuf"
              "yaml"
              "json"
              "markdown"
              "html"
              "css"
              "zig"
              "c"
              "cpp"
              "go"
              "python"
              "bash"
              "kotlin"
              "fish"
              "javascript"
              "typescript"
              "sway"
              "diff"
              "comment"
              "vue"
              "nu"
              "typst"
              "scheme"
            ];
      };

      # sha256 = "0000000000000000000000000000000000000000000000000000";

      nur-pkgs = inputs.nur-pkgs.packages.${system};

      # linuxPackages_latest =
      #   (import inputs.nixpkgs-pin-kernel {
      #     inherit system; config = {
      #     allowUnfree = true;
      #   };
      #   }).linuxPackages_latest;

      blesh = prev.blesh.overrideAttrs (old: {
        src = prev.fetchzip {
          url = "https://github.com/akinomyoga/ble.sh/releases/download/v0.4.0-devel3/ble-0.4.0-devel3.tar.xz";
          sha256 = "kGLp8RaInYSrJEi3h5kWEOMAbZV/gEPFUjOLgBuMhCI=";
        };
      });

      # BUGGY
      # swaylock = prev.swaylock.overrideAttrs (old: {
      #   src = prev.fetchFromGitHub {
      #     owner = "mortie";
      #     repo = "swaylock-effects";
      #     rev = "v1.6-4";
      #     sha256 = "sha256-nYA8W7iabaepiIsxDrCkG/WIFNrVdubk/AtFhIvYJB8=";
      #   };
      # });
      # sway-unwrapped = inputs.nixpkgs-wayland.packages.${system}.sway-unwrapped;


      # sway-unwrapped =
      #   (import inputs.nixpkgs-gui
      #     {
      #       inherit system;
      #     }).sway-unwrapped;

      fscan = (import
        inputs.nixpkgs-master
        {
          system = "x86_64-linux";
        }).fscan;

      factorio-headless = (import inputs.nixpkgs-factorio {
        system = "x86_64-linux";
        config.allowUnfree = true;
      }).factorio-headless;

      fd_iuBrGE = (import
        inputs.nixpkgs-22
        {
          system = "x86_64-linux";
        }).pkgsCross.aarch64-multiplatform.OVMF.fd;

      scx = inputs.nyx.packages.${prev.system}.scx;
      # fishPlugins.foreign-env = prev.fishPlugins.foreign-env.overrideAttrs
      #   (old: {
      #     preInstall = old.preInstall + (with prev; ''
      #       sed -e "s|'env'|'${coreutils}/bin/env'|" -i functions/*
      #     '');
      #   });

      picom = prev.picom.overrideAttrs
        (old: {
          src = prev.fetchFromGitHub {
            owner = "yshui";
            repo = "picom";
            rev = "0fe4e0a1d4e2c77efac632b15f9a911e47fbadf3";
            sha256 = "sha256-daLb7ebMVeL+f8WydH4DONkUA+0D6d+v+pohJb2qjOo=";
          };
        });
      phantomsocks = with prev;
        buildGoModule rec {
          pname = "phantomsocks";
          version = "unstable-2023-11-30";

          src = fetchFromGitHub {
            owner = "macronut";
            repo = pname;
            rev = "b1b13c5b88cf3bac54f39c37c0ffcb0b46e31049";
            hash = "sha256-ptCzd2/8dNHjAkhwA2xpZH8Ki/9DnblHI2gAIpgM+8E=";
          };

          vendorHash = "sha256-0MJlz7HAhRThn8O42yhvU3p5HgTG8AkPM0ksSjWYAC4=";

          ldflags = [
            "-s"
            "-w"
          ];
          buildInputs = [ libpcap ];
          tags = [ "pcap" ];
        };

      dae-unstable =
        with prev;
        buildGoModule rec {
          pname = "dae";
          version = "unstable";

          src = fetchFromGitHub {
            owner = "daeuniverse";
            repo = "dae";
            rev = "75e9e1210ed221b7a11c6f40e75dd5639fbe3b9a";
            hash = "sha256-TmtJtla8kXlK0sCjSjC44pXsEZpL7+UEHgF7nlzrJkU=";
            fetchSubmodules = true;
          };

          vendorHash = "sha256-UQRM3/JSsPDAGqYZ43bVYVvSLvqqZ/BJE6hwx5wzfcQ=";

          proxyVendor = true;

          nativeBuildInputs = [ clang ];

          ldflags = [
            "-s"
            "-w"
            "-X github.com/daeuniverse/dae/cmd.Version=${version}"
            "-X github.com/daeuniverse/dae/common/consts.MaxMatchSetLen_=64"
          ];

          preBuild = ''
            make CFLAGS="-D__REMOVE_BPF_PRINTK -fno-stack-protector -Wno-unused-command-line-argument" \
            NOSTRIP=y \
            ebpf
          '';

          # network required
          doCheck = false;

          postInstall = ''
            install -Dm444 install/dae.service $out/lib/systemd/system/dae.service
            substituteInPlace $out/lib/systemd/system/dae.service \
              --replace /usr/bin/dae $out/bin/dae
          '';
        };



      # dae-unstable = prev.dae.overrideAttrs (old:
      #   let
      #     version = "unstable";
      #     src = prev.fetchFromGitHub {
      #       owner = "daeuniverse";
      #       repo = "dae";
      #       rev = "9ed6b379393f545f1ec529e8777a2ba988642960";
      #       hash = "sha256-gRQhlwX5uUEoghOvky+MnecmHcLAKXPqsORfNXExTGU=";
      #     };
      #   in
      #   rec {
      #     name = "dae-${version}";
      #     inherit src;
      #     goModules = (prev.buildGoModule {
      #       inherit name src;
      #       vendorHash = "sha256-AKk7VRKWdbiF5zzJ8XRxi9b1Y7AYq701m/Agi9TOQqI=";
      #     }).goModules;
      #   });

      via = prev.via.overrideAttrs
        (old: rec{
          version = "2.0.5";
          src = prev.fetchurl {
            url = "https://github.com/the-via/releases/releases/download/v${version}/via-${version}-linux.AppImage";
            name = "via-${version}-linux.AppImage";
            sha256 = "sha256-APNtzfeV6z8IF20bomcgMq7mwcK1fbDdFF77Xr0UPOs=";

          };
        }
        );

      # waybar = prev.waybar.overrideAttrs (old: {
      #   patchPhase = ''
      #     sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
      #   '';
      #   mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ];
      # });


      # rathole = prev.rathole.overrideAttrs
      #   (old: rec {
      #     version = "0.4.8-patch";
      #     src = prev.fetchFromGitHub {
      #       owner = "oluceps";
      #       repo = "rathole";
      #       rev = "9727e15377d9430cd2d3b97f2292037048610209";
      #       sha256 = "sha256-yqZPs0rp3LD7n4+JGa55gZ4xMcumy+oazrxCqpDzIfQ=";
      #     };

      #     cargoDeps = old.cargoDeps.overrideAttrs (prev.lib.const {
      #       inherit src;
      #       # otherwise the old "src" will be used.
      #       outputHash = "sha256-BZ6AgH/wnxrDLkyncR0pbayae9v5P7X7UnlJ48JR8sM=";
      #     });
      #   });

      # rio = prev.rathole.overrideAttrs
      #   (old: rec {
      #     src = prev.fetchFromGitHub {
      #       owner = "raphamorim";
      #       repo = "rio";
      #       rev = "12e9142d259969a08794b0098505f4328dbd0321";
      #       hash = "";
      #     };

      #     cargoDeps = old.cargoDeps.overrideAttrs (prev.lib.const {
      #       inherit src;
      #       # otherwise the old "src" will be used.
      #       outputHash = "";
      #     });
      #   });

      # shadowsocks-rust = prev.shadowsocks-rust.overrideAttrs (old: rec {
      #   version = "1.15.0-alpha.9";
      #   src = prev.fetchFromGitHub {
      #     owner = "shadowsocks";
      #     repo = "shadowsocks-rust";
      #     rev = "ff3590a830a84b4ee4f4b98623897487eed43196";
      #     sha256 = "sha256-mNxnF3xozMCnyVwwIbMjxuH0IRmqXENJePARDmvfNRo=";
      #   };
      #   cargoDeps = old.cargoDeps.overrideAttrs (prev.lib.const {
      #     inherit src;
      #     # otherwise the old "src" will be used.
      #     outputHash = "sha256-i+lGMSp3RqaEiXUzfn0IItCPEagAksVBBZcUQogxizg=";
      #   });
      # });
      #    tdesktop = prev.tdesktop.overrideAttrs
      #      (old: {
      #        version = "4.3.0";
      #        nativeBuildInputs = lib.remove "glibmm" (old.nativeBuildInputs or [ ]) ++ [ final.glibmm_2_68 ];
      #        src = prev.fetchFromGitHub {
      #          owner = "telegramdesktop";
      #          repo = "tdesktop";
      #          rev = "v4.3.0";
      #          fetchSubmodules = true;
      #          sha256 = "1ji9351vcvydkcrdwqx22j1nhl9vysd6ajvghaqxdirvqypiygj0";
      #        };
      #      });


      #      tdesktop = prev.tdesktop.overrideAttrs (old: {
      #        pname = "t64";
      #        version = "1.0.46";
      #        src = pkgs.fetchFromGitHub {
      #          owner = "TDesktop-x64";
      #          repo = "tdesktop";
      #          rev = "1.0.46";
      #          fetchSubmodules = true;
      #          deepClone = true;
      #          sha256 = "hr1dSl1ymwMzVnQri47D41ui8fPLHgD9wN9veQ2ifDM=";
      #        };
      #      });
      #



      record-status = prev.writeShellScriptBin
        "record-status"
        ''
          pid=`pgrep wf-recorder`
          status=$?
          if [ $status != 0 ]
          then
            echo '';
          else
            echo '';
          fi;
        '';

      screen-recorder-toggle = prev.writeShellScriptBin
        "screen-recorder-toggle"
        ''
          pid=`${prev.procps}/bin/pgrep wl-screenrec`
          status=$?
          if [ $status != 0 ]
          then
            ${prev.wl-screenrec}/bin/wl-screenrec -g "$(${prev.slurp}/bin/slurp)" -f $HOME/Videos/record/$(date +'recording_%Y-%m-%d-%H%M%S.mp4');
          else
            ${prev.procps}/bin/pkill --signal SIGINT wl-screenrec
          fi;
        '';

      save-clipboard-to = prev.writeShellScriptBin
        "save-clipboard-to"
        ''
          wl-paste > $HOME/Pictures/Screenshots/$(date +'shot_%Y-%m-%d-%H%M%S.png')
        '';
      switch-mute = final.nuenv.writeScriptBin
        {
          name = "switch-mute";
          script = let pamixer = prev.lib.getExe prev.pamixer; in ''
            ${pamixer} --get-mute | str trim | if $in == "false" { ${pamixer} -m } else { ${pamixer} -u }
          '';
        };

      clean-home = final.nuenv.writeScriptBin
        {
          name = "clean-home";
          script = ''
            cd /home/riro/
            ls | each {|i| findmnt $i.name | if $in == "" { rm -rf $i.name}}
            cd -
          '';
        };
      systemd-run-app = prev.writeShellApplication
        {
          name = "systemd-run-app";
          text = ''
            name=$(${prev.coreutils}/bin/basename "$1")
            id=$(${prev.openssl}/bin/openssl rand -hex 4)
            exec systemd-run \
              --user \
              --scope \
              --unit "$name-$id" \
              --slice=app \
              --same-dir \
              --collect \
              --property PartOf=graphical-session.target \
              --property After=graphical-session.target \
              -- "$@"
          '';
        };
    })

]
