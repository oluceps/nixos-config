inputs:
let lib = inputs.nixpkgs.lib; in
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

    via = prev.via.overrideAttrs (old: rec{
      version = "2.0.5";
      src = prev.fetchurl {
        url = "https://github.com/the-via/releases/releases/download/v${version}/via-${version}-linux.AppImage";
        name = "via-${version}-linux.AppImage";
        sha256 = "sha256-APNtzfeV6z8IF20bomcgMq7mwcK1fbDdFF77Xr0UPOs=";

      };
    }
    );

    waybar = prev.waybar.overrideAttrs (old: {
      patchPhase = ''
        sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
      '';
      mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ];
    });



    shadowsocks-rust = prev.shadowsocks-rust.overrideAttrs (old: rec {
      version = "1.15.0-alpha.9";
      src = prev.fetchFromGitHub {
        owner = "shadowsocks";
        repo = "shadowsocks-rust";
        rev = "ff3590a830a84b4ee4f4b98623897487eed43196";
        sha256 = "sha256-mNxnF3xozMCnyVwwIbMjxuH0IRmqXENJePARDmvfNRo=";
      };
      cargoDeps = old.cargoDeps.overrideAttrs (prev.lib.const {
        inherit src;
        # otherwise the old "src" will be used.
        outputHash = "sha256-9agDj1v/mXuWMSAJ6fCrg1ZEojggcB0I2kYXRVBfMGQ=";
      });
    });
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


  })

]
