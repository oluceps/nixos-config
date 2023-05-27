{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "all_cn";
  version = "1685223206";

  src = fetchurl {
    url = "https://ispip.clang.cn/all_cn.txt";
    sha256 = "sha256-J599+1Ph1VaqCIGoc7I7ArVljxGOpc5e/hMqlOHdPNQ=";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -m 0644 $src -D $out/all_cn.txt
    runHook postInstall
  '';
}
