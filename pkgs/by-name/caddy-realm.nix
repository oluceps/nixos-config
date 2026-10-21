{
  lib,
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
    # Forward proxy for the authenticated Internet gateway. The module publishes
    # no tags, so this pseudo-version pins the commit it was reviewed at.
    "github.com/caddyserver/forwardproxy@v0.0.0-20260321230143-0aab84dad4fc"
    "github.com/oluceps/caddy-plugins-realm/srv@v0.1.0"
    "github.com/oluceps/caddy-plugins-realm/spiffe@v0.0.0-20261021095302-203d2c138a9e"
  ];
  hash = "sha256-tqLJwrtKXtX2w+4smd83Q73sYhVaZRJP4GJQVotT+Pg=";
}).overrideAttrs
  (previous: {
    # build-info proves the modules were required; list-modules proves they
    # registered the handlers the configuration depends on.
    installCheckPhase = previous.installCheckPhase + ''
      $out/bin/caddy list-modules | grep -Fx http.handlers.forward_proxy
      $out/bin/caddy list-modules | grep -Fx layer4.handlers.srv_proxy
      $out/bin/caddy list-modules | grep -Fx tls.get_certificate.spiffe
      $out/bin/caddy list-modules | grep -Fx tls.ca_pool.source.spiffe
    '';
  })
