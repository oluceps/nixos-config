{ reIf, pkgs, ... }:
reIf {
  services.mysql = {
    enable = true;
    package = pkgs.mariadb_1011;
    dataDir = "/var/lib/mysql";
    ensureDatabases = [ "photoprism" ];
    ensureUsers = [
      {
        name = "riro";
        ensurePermissions = {
          "*.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "photoprism";
        ensurePermissions = {
          "photoprism.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
