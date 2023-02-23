{ stdenv
, lib
, fetchurl
, pkgs
, gzip
, autoPatchelfHook
,
}:
stdenv.mkDerivation rec {
  pname = "clash-premium";
  version = "2022.07.07";

  src = fetchurl {
    url = "https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-amd64-v3-${version}.gz";
    sha256 = "sha256-CSFBcRzcp0aUpJqiiD0/zG7ee8IKu7RL3df/b6p+/YE=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    gzip
  ];

  # Secirian
  unpackPhase = ''
    cp $src clash.gz
    gunzip clash.gz
  '';
  sourceRoot = ".";
  #
  #  buildPhase = ''
  #    gunzip clash-linux-amd64-v3-${version}.gz
  #  '';
  #
  installPhase = ''
    install -m755 -D clash $out/bin/clash
  '';

  #   install -m755 -D clash-linux-amd64-v3-${version} $out/bin/clash-premium
  meta = with lib; {
    homepage = "https://github.com/Dreamacro/clash";
    description = "clash";
    platforms = platforms.linux;
  };
}
