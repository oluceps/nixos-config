inputs:
[
  (final: prev: {

        # sha256 = "0000000000000000000000000000000000000000000000000000";
    #      nur-pkgs = inputs.nur-pkgs.packages."${prev.system}";


    picom = prev.picom.overrideAttrs (old: {
      src = prev.fetchFromGitHub {
        owner = "yshui";
        repo = "picom";
        rev = "0fe4e0a1d4e2c77efac632b15f9a911e47fbadf3";
        sha256 = "sha256-daLb7ebMVeL+f8WydH4DONkUA+0D6d+v+pohJb2qjOo=";
      };
    });

    #      waybar = prev.waybar.overrideAttrs (old: {
    #        patchPhase = ''
    #          sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
    #        '';
    #        mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ];
    #      });
    #


    shadowsocks-rust = prev.shadowsocks-rust.overrideAttrs (old: rec {
      version = "1.15.0-alpha.8";
      src = prev.fetchFromGitHub {
        owner = "shadowsocks";
        repo = "shadowsocks-rust";
        rev = "00df9d3c4d2222806485960924256c8f41f17aff";
        sha256 = "sha256-OTgBCDwfILPDrEoZjdYzqcT82th8RYWcKnVWIaC/z3U=";
      };
      cargoDeps = old.cargoDeps.overrideAttrs (prev.lib.const {
        inherit src;
        # otherwise the old "src" will be used.
        outputHash = "sha256-M2Tmh4P46thCgwu2SojuMdYtcemkwxt9mPUfGAl43t0=";
      });
    });


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


  })

]
