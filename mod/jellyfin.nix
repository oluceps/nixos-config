{
  flake.modules.nixos.jellyfin =
    { pkgs, ... }:
    {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
      };
      realm.workloads.jellyfin = {
        isolation.dns = true;
        ingress.http = {
          port = 18096;
          target = "127.0.0.1:8096";
          privateLoopback = true;
          consulService = "jellyfin";
          allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
        };
        egress.internet = {
          service = "internet-proxy";
          verifyID = "spiffe://nyaw.xyz/service/internet";
          localPort = 13128;
        };
      };
      systemd.services.jellyfin.environment = {
        http_proxy = "http://127.0.0.1:13128";
        https_proxy = "http://127.0.0.1:13128";
        no_proxy = "localhost,127.0.0.1,::1";
        HTTP_PROXY = "http://127.0.0.1:13128";
        HTTPS_PROXY = "http://127.0.0.1:13128";
        NO_PROXY = "localhost,127.0.0.1,::1";
        JELLYFIN_PublishedServerUrl = "https://jellyfin.nyaw.xyz";
      };
      environment.systemPackages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
      ];
      systemd.services.jellyfin.serviceConfig.SupplementaryGroups = [ "rqbit" ];
      nixpkgs.overlays = [
        (final: prev: {
          jellyfin-web = prev.jellyfin-web.overrideAttrs (
            finalAttrs: previousAttrs: {
              installPhase = ''
                runHook preInstall
                sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html
                mkdir -p $out/share
                cp -a dist $out/share/jellyfin-web
                runHook postInstall
              '';
            }
          );
        })
      ];
    };
}
