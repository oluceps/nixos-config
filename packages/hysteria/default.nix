{ lib
, fetchFromGitHub
, buildGoModule
}:
buildGoModule rec {
  pname = "hysteria";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "HyNetwork";
    repo = pname;
    rev = "fcc2f06bc1f2aa1d926ef7229e55f5698886ec3e";
    sha256 = "sha256-NstLhrf9XdulKsWDvX/5D0i3zwAc402PccbLsUzTID8=";
  };

  vendorSha256 = "sha256-a24NyJDatyM+j29vyY5zbPRhRTOGfa2c1FkZdKpDvxk=";
  proxyVendor = true;

  ldflags = [
    "-s"
    "-w"
    "-X main.appVersion=${version}"
  ];

  postInstall = ''
    mv $out/bin/cmd $out/bin/hysteria
  '';

  # Network required
  doCheck = false;

  meta = with lib; {
    description = "A feature-packed proxy & relay utility optimized for lossy, unstable connections";
    homepage = "https://github.com/HyNetwork/hysteria";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ oluceps ];
  };
}
