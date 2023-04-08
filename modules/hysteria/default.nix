let
  genHysteriaConfig = name:

    { pkgs
    , config
    , user
    , lib
    , ...
    }:
      with lib;
      let
        cfg = config.services.${name};
      in
      {
        options.services.${name} = {
          enable = mkOption {
            type = types.bool;
            default = false;
          };
          package = mkOption {
            type = types.package;
            default = pkgs.hysteria;
            defaultText = literalExpression "pkgs.hysteria";
            description = lib.mdDoc ''
              package
            '';

          };
        };
        config =
          let
            configFile =
              # hyst-az -> azure server
              # hyst-do -> digital ocean
              # hyst-am -> amazon cloud
              config.age.secrets.${name}.path;
          in
          mkIf
            cfg.enable
            {
              systemd.services.${name} = {
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" "dae.service" ];
                description = "hysteria daemon";

                serviceConfig = {
                  Type = "simple";
                  User = "proxy";
                  ExecStart = "${cfg.package}/bin/hysteria client -c ${configFile}";
                  AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
                  Restart = "on-failure";
                };
              };
            };


      };
in
genHysteriaConfig

