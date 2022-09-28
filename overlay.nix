inputs:
let pkgs = inputs.nixpkgs; in
[
  (final: prev: {
    # sha256 = "0000000000000000000000000000000000000000000000000000";
    #      nur-pkgs = inputs.nur-pkgs.packages."${prev.system}";


    picom = prev.picom.overrideAttrs (old: {
      src = prev.fetchFromGitHub {
        owner = "Arian8j2";
        repo = "picom";
        rev = "31d25da22b44f37cbb9be49fe5c239ef8d00df12";
        sha256 = "1z4bKDoNgmG40y2DKTSSh1NCafrE1rkHkCB3ob8ibm4=";
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
