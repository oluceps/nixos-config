{ pkgs
, ...
}:
{

  config =
    let
      file = pkgs.writeText "lastuser" ''
        riro
      '';

    in
    {
      systemd.services.create-lastuser = {
        description = "create lastuser for tuigreet";

        serviceConfig = {
          Type = "oneshot";
          PreStart = "mkdir /var/cache/tuigreet";
          ExecStart = "ln -sf /var/cache/tuigreet/ ${file}";
          Restart = "on-failure";
        };

      };

    };


}


