{
  lib,
  caddy,
}:
# Minimal Caddy with only the SRV discovery handler, used by the standalone
# `realm-discovery.service` on nodes without the shared Caddy profile.
(caddy.withPlugins {
  plugins = [ "github.com/oluceps/caddy-plugins-realm/srv@v0.1.0" ];
  hash = "sha256-vDXP6mWINXyM60222WucX4Dki0YfFMxuEBgC/HFLiVI=";
}).overrideAttrs
  (previous: {
    installCheckPhase = previous.installCheckPhase + ''
      $out/bin/caddy list-modules | grep -Fx layer4.handlers.srv_proxy
    '';
  })
