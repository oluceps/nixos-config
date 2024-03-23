{ lib
, buildGo122Module
, fetchFromGitHub
}:
buildGo122Module {
  pname = "mosproxy";
  version = "unstable";
  src = fetchFromGitHub ({
    owner = "IrineSistiana";
    repo = "mosproxy";
    rev = "00b5856603a6d858f37831a725391da4296b8007";
    hash = "sha256-KYsHbcXsLoSZRjw66SUdHBI/4tN697nzqQIRxMPgQtI=";
  });
  vendorHash = "sha256-cTKjJ/NmEHElBuagzYOozjrbP2hSHDfUrizdCilP41U=";
  doCheck = false;
  ldflags = [
    "-s"
    "-w"
  ];
  meta = with lib; {
    description = "A DNS proxy server";
    homepage = "https://github.com/IrineSistiana/mosproxy";
    license = licenses.gpl3;
  };
}
