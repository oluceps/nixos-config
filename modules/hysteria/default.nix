{ pkgs
, config
, lib
, user
, ...
}:
with lib;
let genHyst = { name }:
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
        default = pkgs.callPackage ../../packages/hysteria { };
        defaultText = literalExpression "pkgs.hysteria";
        description = lib.mdDoc ''
          package
        '';

      };
    };



    config =
      let configFile =
        let token = if name == "hysteria" then "hyst" else "hyst-do";
        in config.age.secrets.${token}.path;
      in
      mkIf
        cfg.enable
        {
          systemd.services.${name} = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            description = "hysteria daemon";

            serviceConfig = {
              Type = "simple";
              User = user;
              ExecStart = "${cfg.package}/bin/hysteria -c ${configFile}";
              AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
              Restart = "on-failure";
            };
          };
        };


  }; in
let name = "hysteria"; in genHyst { inherit name; }

