{
  lib,
  stdenv,
  fetchurl,
  stdenvNoCC,
  wrapGAppsHook3,
  cargo-tauri,
  autoPatchelfHook,
  mihomo,
  v2ray-domain-list-community,
  v2ray-geoip,
  openssl,
  makeDesktopItem,
  pkg-config,
  webkitgtk,
  udev,
  libayatana-appindicator,
  nix-update-script,
  fetchFromGitHub,
  pnpm,
  nodejs,
  rustPlatform,
  darwin,
  rust,
}:
let
  # declare components and resources required on runtime
  service_components = rustPlatform.buildRustPackage {
    pname = "clash-verge-service";
    version = "unstable-2024-06-28";

    src = fetchFromGitHub {
      owner = "clash-verge-rev";
      repo = "clash-verge-service";
      rev = "e33024d74e1a96bd0385943fcc541818301ee886";
      hash = "sha256-EUeZBwmcDnSci9MHIK/s44wp7ah/daMWbj2wTkHa9vc=";
    };

    cargoHash = "sha256-e9/cvh4TpgwMifRptWG1+dc4yn+JqRcWriEVmZ3lI28=";

    nativeBuildInputs = [ pkg-config ];

    buildInputs =
      [ openssl ]
      ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.IOKit
        darwin.apple_sdk.frameworks.Security
      ];

    env = {
      OPENSSL_NO_VENDOR = true;
    };
  };

  set_dns = fetchurl {
    url = "https://github.com/clash-verge-rev/set-dns-script/releases/download/script/set_dns.sh";
    hash = "sha256-3L31/3ODy2I5pRDVjKH46tVjTQ+2pJFKEkK+ZxBNr4E=";
  };
  unset_dns = fetchurl {
    url = "https://github.com/clash-verge-rev/set-dns-script/releases/download/script/unset_dns.sh";
    hash = "sha256-Nj0bYqUvtxxMVi1Kv5OydWrmO+fhJyMUkSeO8AnjWmo=";
  };
  country = fetchurl {
    url = "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb";
    hash = "sha256-eb5jeWzpP/nblMBGTMDsXSYh/rD5jxk/RWpDNFtyhTs=";
  };

  # using tauri 1.6.0
  cargo-tauri-160 = cargo-tauri.overrideAttrs (old: rec {
    version = "1.6.0";
    src = fetchFromGitHub {
      owner = "tauri-apps";
      repo = "tauri";
      rev = "tauri-v${version}";
      hash = "sha256-0LKkGpbDT6bRzoggDmTmSB8UaT11OME7OXsr+M67WVU=";
    };
    cargoDeps = old.cargoDeps.overrideAttrs (
      lib.const {
        inherit src;
        # otherwise the old "src" will be used.
        outputHash = "sha256-V08OY6nZQ+0SOQtH8/Q2APnZcOgZkHSBis14rxWkgmQ=";
      }
    );
  });

in
rustPlatform.buildRustPackage rec {
  pname = "clash-verge-rev";
  version = "1.7.2-unstable-2024-07-04";

  src = fetchFromGitHub {
    owner = "clash-verge-rev";
    repo = "clash-verge-rev";
    rev = "5b7b3be6f9623ccb04bf96972f08f6146cf866dd";
    hash = "sha256-3RyqvYquuX52o+TfD+NnwlQ/laRoquwhVnMOEEz9eWU=";
  };

  ui = stdenvNoCC.mkDerivation {
    inherit src version;
    pname = "${pname}-ui";

    pnpmDeps = pnpm.fetchDeps {
      inherit pname version src;
      hash = "sha256-PEK07nXWoemhqYAHp2+feh7OpMlMDdp+OyJLh52F7S4=";
    };

    nativeBuildInputs = [
      nodejs
      pnpm.configHook
    ];

    buildPhase = ''
      runHook preBuild

      pnpm web:build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -r dist $out

      runHook postInstall
    '';
  };

  sourceRoot = "${src.name}/src-tauri";

  cargoLock = {
    lockFile = "${src}/src-tauri/Cargo.lock";
    outputHashes = {
      "sysproxy-0.3.0" = "sha256-TEC51s/viqXUoEH9rJev8LdC2uHqefInNcarxeogePk=";
    };
  };

  env = {
    OPENSSL_NO_VENDOR = 1;
  };

  postPatch = ''
    substituteInPlace ./tauri.conf.json \
      --replace-fail '"distDir": "../dist",' '"distDir": "${ui}",' \
      --replace-fail '"beforeBuildCommand": "pnpm run web:build"' '"beforeBuildCommand": ""'

    # install mihomo 
    mkdir -p ./sidecar
    ln -s ${mihomo}/bin/mihomo sidecar/verge-mihomo-x86_64-unknown-linux-gnu
    ln -s ${mihomo}/bin/mihomo sidecar/verge-mihomo-alpha-x86_64-unknown-linux-gnu

    # install resources
    mkdir -p ./resources
    ln -s ${set_dns} resources/set_dns.sh
    ln -s ${unset_dns} resources/unset_dns.sh
    ln -s ${country} resources/Country.mmdb
    ln -s ${v2ray-domain-list-community}/share/v2ray/geosite.dat resources/geosite.dat 
    ln -s ${v2ray-geoip}/share/v2ray/geoip.dat resources/geoip.dat 

    ln -s ${service_components}/bin/clash-verge-service resources/clash-verge-service
    ln -s ${service_components}/bin/install-service resources/install-service
    ln -s ${service_components}/bin/uninstall-service resources/uninstall-service
  '';

  nativeBuildInputs = [
    wrapGAppsHook3
    pkg-config
    rustPlatform.cargoSetupHook
    cargo-tauri-160
  ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  buildInputs = [
    openssl
    webkitgtk
    stdenv.cc.cc
  ];

  runtimeDependencies = [
    (lib.getLib udev)
    libayatana-appindicator
  ];

  postInstall = ''
    install -DT icons/256x256@2x.png $out/share/icons/hicolor/256x256@2/apps/clash-verge.png
    install -DT icons/128x128.png $out/share/icons/hicolor/128x128/apps/clash-verge.png
    install -DT icons/32x32.png $out/share/icons/hicolor/32x32/apps/clash-verge.png
  '';

  postFixup = ''
    mkdir -p $out/lib/clash-verge/resources
    install -Dm755 ${service_components}/bin/{clash-verge,install,uninstall}-service $out/lib/clash-verge/resources

    ln -s ${set_dns} $out/lib/clash-verge/resources/set_dns.sh
    ln -s ${unset_dns} $out/lib/clash-verge/resources/unset_dns.sh
    ln -s ${country} $out/lib/clash-verge/resources/Country.mmdb
    ln -s ${v2ray-domain-list-community}/share/v2ray/geosite.dat $out/lib/clash-verge/resources/geosite.dat 
    ln -s ${v2ray-geoip}/share/v2ray/geoip.dat $out/lib/clash-verge/resources/geoip.dat 
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = "clash-verge %u";
      icon = pname;
      desktopName = "PreMiD";
      genericName = meta.description;
      mimeTypes = [ "x-scheme-handler/clash" ];
      type = "Application";
      terminal = false;
    })
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Clash GUI based on tauri";
    homepage = "https://github.com/zzzgydi/clash-verge";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ zendo ];
    mainProgram = "clash-verge-rev";
  };
}
