{ lib
, fetchFromGitHub
, buildGoModule
}:
buildGoModule rec {
  pname = "clash-meta";
  version = "1.13.1";

  src = fetchFromGitHub {
    owner = "MetaCubeX";
    repo = "Clash.Meta";
    rev = "5987f8e3b5d489c577328c4cbc147432cb45a498";
    sha256 = "sha256-A6StmjCyz0v0vhiywPmuAePL8p1UYrx6BREXOmby9Xk=";
  };

  vendorSha256 = "sha256-vYNYhUs8zFuFhhUJAt+ybombJs+aVWinNJ4EtQK0wtQ=";

  # Do not build testing suit
  excludedPackages = [ "./test" ];

  CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/Dreamacro/clash/constant.Version=${version}"
  ];

  # network required
  doCheck = false;

  meta = with lib; {
    description = "Another Clash Kernel";
    homepage = "https://github.com/MetaCubeX/Clash.Meta";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ oluceps ];
  };
}
