{
  lib,
  caddy,
  caddy-srv,
}:
let
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.0.0-20250724223520-f589a18c0f5d"
    "github.com/mholt/caddy-ratelimit@v0.1.0"
    "github.com/ss098/certmagic-s3@v0.0.0-20250607141218-0c4ff782fbd0"
    "github.com/greenpau/caddy-security@v1.1.31"
    "github.com/mholt/caddy-l4@v0.0.0-20260112235400-e24201789f06"
    "nyaw.xyz/caddy-l4-srv@v0.1.0=${caddy-srv.pluginSource}"
  ];
  base = caddy.withPlugins {
    inherit plugins;
    hash = "sha256-Q8B5+iuUlShK2fYLh5MWnkvCukfnII+w3JKkVFpsKU0=";
    # nixpkgs' version checker does not understand local module replacements.
    doInstallCheck = false;
  };
in
base.overrideAttrs (_: {
  # A fixed-output source cannot retain a reference to the local plugin's
  # store path. Keep the replacement inside the generated source instead.
  src = base.src.overrideAttrs (old: {
    buildPhase = old.buildPhase + ''
      (
        cd buildenv*
        cp -R ${caddy-srv.pluginSource} realm-plugin
        chmod -R u+w realm-plugin
        go mod edit -replace=nyaw.xyz/caddy-l4-srv@v0.1.0=./realm-plugin
        substituteInPlace vendor/modules.txt \
          --replace-fail '${caddy-srv.pluginSource}' './realm-plugin'
      )
    '';
  });
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/caddy list-modules | grep -Fx layer4.handlers.srv_proxy
    $out/bin/caddy build-info > build-info.txt
    ${lib.concatMapStringsSep "\n" (
      plugin:
      let
        module = builtins.head (lib.splitString "@" plugin);
      in
      ''
        grep -F '${module}' build-info.txt
      ''
    ) plugins}
    runHook postInstallCheck
  '';
})
