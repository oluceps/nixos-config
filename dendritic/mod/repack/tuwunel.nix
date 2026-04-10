{ lib, ... }:
{
  flake.modules.nixos.tuwunel =
    { config, lib, ... }:
    {
      options.repack.tuwunel.enable = lib.mkEnableOption "tuwunel";
      config = lib.mkIf config.repack.tuwunel.enable {
        systemd.services.tuwunel.serviceConfig = {
          ReadWritePaths = [ "/var/lib/backup/tuwunel" ];
          Environment = [ "TUWUNEL_LOG=info" ];
        };
        services.tuwunel = {
          enable = true;
          settings.global = {
            server_name = "nyaw.xyz";
            port = [ 6167 ];
            address = [ "::" ];
            dns_tcp_fallback = false;
            ip_lookup_strategy = 5;
            database_backup_path = "/var/lib/backup/tuwunel";
            turn_uris = [
              "turn:yidhra.nyaw.xyz?transport=udp"
              "turn:yidhra.nyaw.xyz?transport=tcp"
            ];
          };
        };
      };
    };
}
