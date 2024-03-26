{ lib
, buildGo122Module
, fetchFromGitHub
}:
buildGo122Module {
  pname = "mosproxy";
  version = "unstable-2024-03-25";
  src = fetchFromGitHub ({
    owner = "IrineSistiana";
    repo = "mosproxy";
    rev = "79ee388da41d7aab8e322cb20e3fe8263a92d099";
    hash = "sha256-INNAe4cMjJ335kxBfxkXhhAl/2Tj5cPc6ooL6E7d4Jg=";
  });
  vendorHash = "sha256-hB0Oak42cGGga3moq+dnEHJ+v2ufcgxavzi9T1m2Uok=";
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
