{
  flake.modules.nixos.calibre =
    { config, ... }:
    {
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
        isolation.runtimePaths = [ "/run/calibre-web" ];
        ingressGroups = [ "calibre" ];
        ingress.http = {
          port = 18083;
          target = "unix:/run/calibre-web/http.sock";
          service = "calibre";
          allowedIDs = config.realm.caddy.allowedIDs.calibre;
        };
        egress.internet = {
          service = "internet-proxy";
          verifyID = "spiffe://nyaw.xyz/service/internet";
          localPort = 13128;
        };
      };
      systemd.services.calibre-web.serviceConfig.RuntimeDirectory = "calibre-web";
      systemd.services.calibre-web.environment = {
        CALIBRE_UNIX_SOCKET = "/run/calibre-web/http.sock";
        HTTP_PROXY = "http://127.0.0.1:13128";
        HTTPS_PROXY = "http://127.0.0.1:13128";
        NO_PROXY = "localhost,127.0.0.1,::1";
      };
    };
}
