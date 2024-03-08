{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec{
  pname = "aliyunpan";
  version = "31aaadfcc1322a2e958f014e35fd5222f7575476";

  src = fetchFromGitHub {
    owner = "tickstep";
    repo = "aliyunpan";
    rev = version;
    hash = "";
  };

  vendorHash = "";

  ldflags = [
    "-s"
    "-w"
  ];
}
