{
  lib,
  buildGoModule,
  writableTmpDirAsHomeHook,
}:
buildGoModule {
  pname = "caddy-srv";
  version = "0.1.0";

  src = lib.cleanSource ./.;
  vendorHash = "sha256-glVfiZXlJruCn3VDb6F6ns1Z75vYJvqChzSxpg1Vh+M=";
  subPackages = [ "cmd/caddy" ];
  tags = [
    "nobadger"
    "nomysql"
    "nopgx"
  ];
  ldflags = [
    "-s"
    "-w"
  ];

  # subPackages only selects the command; test the plugin package as well.
  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';
  nativeCheckInputs = [ writableTmpDirAsHomeHook ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/caddy list-modules | grep -Fx layer4.handlers.srv_proxy
    runHook postInstallCheck
  '';

  # Keep documentation and packaging edits out of the xcaddy source hash.
  passthru.pluginSource = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./srv.go
      ./go.mod
      ./go.sum
      ./LICENSE
    ];
  };

  meta = {
    description = "Caddy with transparent L4 DNS SRV discovery";
    license = lib.licenses.mit;
    mainProgram = "caddy";
    platforms = lib.platforms.linux;
  };
}
