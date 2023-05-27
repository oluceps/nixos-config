{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "accelerated-domains-cn";
  version = "1685223206";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/yubanmeiqin9048/domain/release/accelerated-domains.china.txt";
    sha256 = "sha256-K2saWe3HoZsgHD+EJ8lV6Pma2hJYNJ23x9fqEYdH1U8=";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -m 0644 $src -D $out/accelerated-domains.china.txt
    runHook postInstall
  '';
}
