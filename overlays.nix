{ inputs, system }:
[
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
      # inputs.hyprland.packages.${system}.default;

      helix = inputs.helix.packages.${system}.default.override {
        includeGrammarIf = grammar:
          prev.lib.any
            (name: grammar.name == name)
            [
              "toml"
              "rust"
              "nix"
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

      # BUGGY
      # swaylock = prev.swaylock.overrideAttrs (old: {
      #   src = prev.fetchFromGitHub {
      #     owner = "mortie";
      #     repo = "swaylock-effects";
      #     rev = "v1.6-4";
      #     sha256 = "sha256-nYA8W7iabaepiIsxDrCkG/WIFNrVdubk/AtFhIvYJB8=";
      #   };
      # });
      # sway-unwrapped = prev.sway-unwrapped.overrideAttrs
      #   (old: {
      #     patches = (old.patches or [ ])
      #     ++ [ ./.attachs/0001-text_input-Implement-input-method-popups.patch ];
      #   });


      # sway-unwrapped =
      #   (import inputs.nixpkgs-gui
      #     {
      #       inherit system;
      #     }).sway-unwrapped;

      fishPlugins.foreign-env = prev.fishPlugins.foreign-env.overrideAttrs
        (old: {
          preInstall = old.preInstall + (with prev; ''
            sed -e "s|'env'|'${coreutils}/bin/env'|" -i functions/*
          '');
        });

      picom = prev.picom.overrideAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "yshui";
          repo = "picom";
          rev = "0fe4e0a1d4e2c77efac632b15f9a911e47fbadf3";
          sha256 = "sha256-daLb7ebMVeL+f8WydH4DONkUA+0D6d+v+pohJb2qjOo=";
        };
      });

      via = prev.via.overrideAttrs (old: rec{
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


      rathole = prev.rathole.overrideAttrs (old: rec {
        version = "0.4.8-patch";
        src = prev.fetchFromGitHub {
          owner = "oluceps";
          repo = "rathole";
          rev = "9727e15377d9430cd2d3b97f2292037048610209";
          sha256 = "sha256-yqZPs0rp3LD7n4+JGa55gZ4xMcumy+oazrxCqpDzIfQ=";
        };

        cargoDeps = old.cargoDeps.overrideAttrs (prev.lib.const {
          inherit src;
          # otherwise the old "src" will be used.
          outputHash = "sha256-BZ6AgH/wnxrDLkyncR0pbayae9v5P7X7UnlJ48JR8sM=";
        });
      });

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



      record-status = prev.writeShellScriptBin "record-status" ''
        pid=`pgrep wf-recorder`
        status=$?
        if [ $status != 0 ]
        then
          echo '';
        else
          echo '';
        fi;
      '';

      screen-recorder-toggle = prev.writeShellScriptBin "screen-recorder-toggle" ''
        pid=`${prev.procps}/bin/pgrep wf-recorder`
        status=$?
        if [ $status != 0 ]
        then
          ${prev.wf-recorder}/bin/wf-recorder -g "$(${prev.slurp}/bin/slurp)" -f $HOME/Videos/record/$(date +'recording_%Y-%m-%d-%H%M%S.mp4') --pixel-format yuv420p;
        else
          ${prev.procps}/bin/pkill --signal SIGINT wf-recorder
        fi;
      '';

      save-clipboard-to = prev.writeShellScriptBin "save-clipboard-to" ''
        wl-paste > $HOME/Pictures/screenshot/$(date +'shot_%Y-%m-%d-%H%M%S.png')
      '';
      switch-mute = final.nuenv.mkScript {
        name = "switch-mute";
        script = let pamixer = prev.lib.getExe prev.pamixer; in ''
          ${pamixer} --get-mute | str trim | if $in == "false" { ${pamixer} -m } else { ${pamixer} -u }
        '';
      };

      systemd-run-app = prev.writeShellApplication {
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
