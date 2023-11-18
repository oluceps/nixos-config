{ min ? false }: { pkgs
                 , config
                 , lib
                 , ...
                 }:
with lib;
let
  cfg = config.services.sing-box;
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  options.services.sing-box = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    webPanel = mkOption {
      type = with types; submodule {
        options = {
          enable = mkEnableOption (mdDoc "enable");
          package = mkPackageOptionMD pkgs "metacubexd" { };
        };
      };
      default = {
        enable = true;
        package = pkgs.metacubexd;
      };
    };
    package = mkOption {
      type = types.package;
      default = pkgs.sing-box;
    };

  };
  config =
    let
      configFile = if ! min then config.age.secrets.sing.path else
      pkgs.writeTextFile {
        name = "config.json";
        text = builtins.readFile ./min.json;
      };


    in
    mkIf cfg.enable {
      systemd.services.sing-box = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        description = "sing-box Daemon";
        serviceConfig = {
          User = "proxy";
          ExecStart = "${lib.getExe cfg.package} run -c ${configFile} -D $STATE_DIRECTORY";
          StateDirectory = "sing";
          CapabilityBoundingSet = [
            "CAP_NET_RAW"
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          AmbientCapabilities = [
            "CAP_NET_RAW"
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          Restart = "on-failure";
        };

      }
      // lib.optionalAttrs cfg.webPanel.enable {
        preStart = "ln -sfT ${cfg.webPanel.package} $STATE_DIRECTORY/web";
      }
      ;

    };


}

