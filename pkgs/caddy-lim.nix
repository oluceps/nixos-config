{
  lib,
  buildGo123Module,
  fetchFromGitHub,
  nixosTests,
  caddy,
  testers,
  installShellFiles,
  stdenv,
}:
let
  version = "2.8.4-lim";
  dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    rev = "v2.8.4";
    hash = "sha256-O4s7PhSUTXoNEIi+zYASx8AgClMC5rs7se863G6w+l0=";
  };
in
buildGo123Module {
  pname = "caddy";
  inherit version;

  src = fetchFromGitHub {
    owner = "oluceps";
    repo = "caddy";
    rev = "f4800137137c30443c299bead6a33c7787dac5b3";
    hash = "sha256-ZYPwkJ+nm8DDEObRxq8XwRlWmUwEwpoyQptgS/vCqA4=";
  };

  vendorHash = "sha256-rOKEsiKa5MettrMiMaAyql1jLIUGzSZ2tNaq8iscdcw=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];

  # matches upstream since v2.8.0
  tags = [ "nobadger" ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall =
    ''
      install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

      substituteInPlace $out/lib/systemd/system/caddy.service \
        --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
      substituteInPlace $out/lib/systemd/system/caddy-api.service \
        --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
    ''
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      # Generating man pages and completions fail on cross-compilation
      # https://github.com/NixOS/nixpkgs/issues/308283

      $out/bin/caddy manpage --directory manpages
      installManPage manpages/*

      installShellCompletion --cmd caddy \
        --bash <($out/bin/caddy completion bash) \
        --fish <($out/bin/caddy completion fish) \
        --zsh <($out/bin/caddy completion zsh)
    '';

  passthru.tests = {
    inherit (nixosTests) caddy;
    version = testers.testVersion {
      command = "${caddy}/bin/caddy version";
      package = caddy;
    };
  };

  meta = with lib; {
    homepage = "https://caddyserver.com";
    description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
    license = licenses.asl20;
    mainProgram = "caddy";
    maintainers = with maintainers; [
      Br1ght0ne
      emilylange
      techknowlogick
    ];
  };
}
