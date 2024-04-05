{ config, ... }:
{
  enable = true;
  virtualHosts = {
    "attic.nyaw.xyz" = {
      forceSSL = true;
      sslCertificate = "/run/credentials/nginx.service/nyaw.cert";
      sslCertificateKey = "/run/credentials/nginx.service/nyaw.key";
      locations = {
        "/" = {
          proxyPass = "http://localhost:8083";
          #   # required when the target is also TLS server with multiple hosts

          #   "proxy_ssl_server_name on;"
          #   +
          #     # required when the server wants to use HTTP Authentication

          #     "proxy_pass_header Authorization;";
        };
      };
    };

    "s3.nyaw.xyz" = {
      forceSSL = true;
      sslCertificate = "/run/credentials/nginx.service/nyaw.cert";
      sslCertificateKey = "/run/credentials/nginx.service/nyaw.key";
      locations = {
        "/" = {
          proxyPass = "http://localhost:9000";
        };
      };
    };
  };
}
