{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "all_cn";
  version = "1686318104";

  src = fetchurl {
    url = "https://ispip.clang.cn/all_cn.txt";
    sha256 = "sha256-ZamLlzE5AwsgShyTJ41SqEAUiRt211KmQ+YMdXhr1yY=";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -m 0644 $src -D $out/all_cn.txt
    runHook postInstall
  '';
}
