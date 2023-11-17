{ buildGo120Module
, fetchFromGitHub
}:

buildGo120Module rec {
  pname = "caddy";
  version = "naive";

  src = fetchFromGitHub {
    owner = "oluceps";
    repo = "caddy";
    rev = "968872791e51dad9b217e0597e74376d826eae94";
    hash = "sha256-7qWaEJ6hlmUCW8x0Rqi9oQPCDtRENNapgVVukrNO50A=";
  };

  vendorHash = "";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];
}
