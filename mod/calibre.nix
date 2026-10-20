{
  flake.modules.nixos.calibre = {
    users.groups.calibre = { };
    services.calibre-web = {
      enable = true;
      group = "calibre";
      listen.ip = "127.0.0.1";
      options = {
        calibreLibrary = "/var/lib/calibre";
        enableBookUploading = true;
        reverseProxyAuth.enable = true;
      };
    };
    realm.workloads.calibre = {
      unit = "calibre-web.service";
      user = "calibre-web";
      group = "calibre";
      ingress.http = {
        port = 18083;
        target = "127.0.0.1:8083";
        privateLoopback = true;
        service = "calibre";
        allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
      };
      egress.internet = {
        service = "internet-proxy";
        verifyID = "spiffe://nyaw.xyz/service/internet";
        localPort = 13128;
      };
    };
    systemd.services.calibre-web.environment = {
      HTTP_PROXY = "http://127.0.0.1:13128";
      HTTPS_PROXY = "http://127.0.0.1:13128";
      NO_PROXY = "localhost,127.0.0.1,::1";
    };
  };
}
