{
  flake.modules.nixos.atuin =
    { config, ... }:
    {
      realm.serviceDiscovery.publish.atuin = {
        unit = "atuin.service";
        port = config.services.atuin.port;
      };

      services.atuin = {
        enable = true;
        host = "fdcc::3";
        port = 8888;
        openFirewall = false;
        openRegistration = false;
        maxHistoryLength = 65536;
        # database.uri = "postgresql://atuin@127.0.0.1:5432/atuin";
        database.uri = "postgresql:///atuin?host=/run/postgresql";

      };
      # systemd.services.atuin.serviceConfig.ExecStart =
      #   lib.mkForce "${(lib.getExe pkgs.atuin)} server start";
    };
}
