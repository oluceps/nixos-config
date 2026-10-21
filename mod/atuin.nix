{
  flake.modules.nixos.atuin =
    { config, ... }:
    {
      realm.workloads.atuin = {
        ingress.http = {
          port = 18888;
          target = "127.0.0.1:8888";
          privateLoopback = true;
          service = "atuin";
          allowedIDs = config.realm.caddy.allowedIDs.atuin;
        };
      };

      services.atuin = {
        enable = true;
        host = "127.0.0.1";
        port = 8888;
        openFirewall = false;
        openRegistration = false;
        maxHistoryLength = 65536;
        database.uri = "postgresql://atuin@localhost/atuin?host=/run/postgresql&sslmode=disable";
      };
      systemd.services.atuin = {
        after = [ "postgresql.target" ];
        requires = [ "postgresql.target" ];
        serviceConfig = {
          BindReadOnlyPaths = [ "/run/postgresql" ];
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
}
