{
  flake.modules.nixos.atuin =
    { ... }:
    {
      realm.workloads.atuin = {
        egress.postgresql = {
          service = "postgresql-atuin";
          verifyID = "spiffe://nyaw.xyz/service/postgresql";
          localPort = 15432;
        };
        ingress.http = {
          port = 18888;
          target = "127.0.0.1:8888";
          privateLoopback = true;
          consulService = "atuin";
          allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
        };
      };

      services.atuin = {
        enable = true;
        host = "127.0.0.1";
        port = 8888;
        openFirewall = false;
        openRegistration = false;
        maxHistoryLength = 65536;
        database.uri = "postgresql://atuin@127.0.0.1:15432/atuin?sslmode=disable";
      };
    };
}
