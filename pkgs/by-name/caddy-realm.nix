{
  caddy,
}:
# The realm plugins live in their own repository so this build references
# published modules instead of a local store path inside a fixed-output
# derivation. See github.com/oluceps/caddy-plugins-realm.
(caddy.withPlugins {
  plugins = [
    "github.com/caddy-dns/cloudflare@v0.0.0-20250724223520-f589a18c0f5d"
    "github.com/mholt/caddy-ratelimit@v0.1.0"
    "github.com/ss098/certmagic-s3@v0.0.0-20250607141218-0c4ff782fbd0"
    "github.com/greenpau/caddy-security@v1.1.31"
    "github.com/mholt/caddy-l4@v0.0.0-20260112235400-e24201789f06"
    "github.com/oluceps/caddy-plugins-realm/spiffe@v0.0.0-20261021095302-203d2c138a9e"
  ];
  hash = "sha256-3PAb64ZVu3qGvs9NzS9a3B2tFHE4wGflHdQtcKTHnWQ=";
}).overrideAttrs
  (previous: {
    # withPlugins' fixed-output src already contains vendor/. Apply local fixes
    # after unpacking it, outside the fixed-output derivation, so the pinned
    # dependency hash stays unchanged and the final derivation tracks the patch.
    patches = (previous.patches or [ ]) ++ [ ../patches/caddy-client-ca-rotation.patch ];
    postPatch = (previous.postPatch or "") + ''
      cp ${../patches/caddy-client-ca-rotation_test.go} \
        vendor/github.com/caddyserver/caddy/v2/modules/caddytls/realm_client_ca_rotation_test.go
    '';
    checkPhase = ''
      runHook preCheck
      go test -race -count=1 -v ./vendor/github.com/caddyserver/caddy/v2/modules/caddytls \
        -run '^TestRealmClientCARotation$'
      runHook postCheck
    '';

    # build-info proves the modules were required; list-modules proves they
    # registered the handlers the configuration depends on.
    installCheckPhase = previous.installCheckPhase + ''
      $out/bin/caddy list-modules | grep -Fx tls.get_certificate.spiffe
      $out/bin/caddy list-modules | grep -Fx tls.ca_pool.source.spiffe
    '';
  })
