{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "accelerated-domains-cn";
  version = "1686318104";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/yubanmeiqin9048/domain/release/accelerated-domains.china.txt";
    sha256 = "sha256-iezvV+PfgRgiDc3OMTwcNqRIZ1y9LT8xYvE/gUaGq7A=";
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -m 0644 $src -D $out/accelerated-domains.china.txt
    runHook postInstall
  '';
}
