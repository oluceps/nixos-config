{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "accelerated-domains-cn";
  version = "1686318104";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/yubanmeiqin9048/domain/release/accelerated-domains.china.txt";
    sha256 = "sha256-rmf9rqGaoN82C6OAK9vO5xtEN+/+b6G4xGMIvzLVuCw=";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -m 0644 $src -D $out/accelerated-domains.china.txt
    runHook postInstall
  '';
}
