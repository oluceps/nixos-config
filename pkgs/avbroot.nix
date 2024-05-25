{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, protobuf
, bzip2
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "avbroot";
  version = "3.2.1";

  src = fetchFromGitHub {
    owner = "chenxiaolong";
    repo = "avbroot";
    rev = "v${version}";
    hash = "sha256-o3XNuTvQivHxluHr/HPnPCl97mUF1sypjmszMsG7haA=";
  };

  cargoLock = {
    lockFile = ./lock/avbroot.lock;
    outputHashes = {
      "bzip2-0.4.4" = "sha256-9YKPFvaGNdGPn2mLsfX8Dh90vR+X4l3YSrsz0u4d+uQ=";
      "zip-0.6.6" = "sha256-oZQOW7xlSsb7Tw8lby4LjmySpWty9glcZfzpPuQSSz0=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    protobuf
  ];

  buildInputs = [
    bzip2
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "Sign (and root) Android A/B OTAs with custom keys while preserving Android Verified Boot";
    homepage = "https://github.com/chenxiaolong/avbroot";
    changelog = "https://github.com/chenxiaolong/avbroot/blob/${src.rev}/CHANGELOG.md";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    mainProgram = "avbroot";
  };
}
