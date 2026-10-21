{
  flake.modules.nixos.realm-internet =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      workload = config.realm.workloads.internet;
      ingress = workload.ingress.http;
      hostName = config.networking.hostName;
      spiffeCA = {
        provider = "spiffe";
        socket_path = config.realm.spire.socket;
      };
      # Stand-in TLS server name: clients dial the mesh address, so the
      # ClientHello carries no SNI and the connection policy supplies one.
      certSubject = "internet-${hostName}";
      denied = {
        handler = "static_response";
        status_code = 403;
      };
      # Destinations the gateway must never reach: loopback, link-local,
      # multicast, other special-purpose ranges and the cluster's own
      # addressing. The ACL is evaluated on the address that is then dialed, so
      # a name cannot resolve to a private address between check and connect.
      privateDestinations = [
        "0.0.0.0/8"
        "10.0.0.0/8"
        "100.64.0.0/10"
        "127.0.0.0/8"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.0.0.0/24"
        "192.168.0.0/16"
        "198.18.0.0/15"
        "224.0.0.0/4"
        "240.0.0.0/4"
        "::/128"
        "::1/128"
        # Not ::ffff:0:0/96: the matcher collapses that prefix to the IPv4
        # 0.0.0.0/0 network, which would deny every IPv4 destination.
        "200::/7"
        "fc00::/7"
        "fe80::/10"
        "fec0::/10"
        "ff00::/8"
      ];
      acl = [
        {
          subjects = privateDestinations;
          allow = false;
        }
        {
          subjects = [ "all" ];
          allow = true;
        }
      ];
      # The forward proxy cannot tell CONNECT from a plain request when it checks
      # the port, so the routes below split the two: a tunnel is limited to 443,
      # an absolute-URI request to 80 and 443. Synapse additionally reaches 8448
      # for federation, which is why its identity selects a third handler.
      forwardProxy = ports: {
        handler = "forward_proxy";
        inherit acl;
        allowed_ports = ports;
        dial_timeout = "10s";
      };
      # Callers authenticate with an SVID from the SPIRE bundle; the URI SAN is
      # then matched against the declared allowlist. The SAN placeholder yields a
      # URL value, so the regular-expression matcher is used to stringify it.
      authorized =
        ids:
        map (id: {
          vars_regexp."{http.request.tls.client.san.uris.0}".pattern = "^${lib.escapeRegex id}$";
        }) ids;
      synapse = {
        vars_regexp."{http.request.tls.client.san.uris.0}".pattern =
          "^${lib.escapeRegex "${config.realm.servicePrefix}synapse"}$";
      };
      # Called by path so the gateway also evaluates without this flake's overlay.
      caddy = pkgs.callPackage ../pkgs/by-name/caddy-realm.nix { };
      format = pkgs.formats.json { };
      configfile = format.generate "realm-internet.json" {
        admin.disabled = true;
        apps = {
          tls.automation.policies = [
            # No subject list on purpose: a policy only applies to a connection
            # whose SNI it matches, and callers dial a mesh address.
            {
              get_certificate = [
                {
                  via = "spiffe";
                  socket_path = config.realm.spire.socket;
                  spiffe_id = workload.spiffeID;
                }
              ];
            }
          ];
          http.servers.internet = {
            listen = [ "[${config.realm.address}]:${toString ingress.port}" ];
            automatic_https.disable = true;
            # Proxy requests carry the destination host in Host, not the
            # gateway's name; Caddy would otherwise require them to match the
            # SNI as soon as client authentication is configured.
            strict_sni_host = false;
            tls_connection_policies = [
              {
                default_sni = certSubject;
                protocol_min = "tls1.3";
                client_authentication = {
                  mode = "require_and_verify";
                  ca = spiffeCA;
                };
              }
            ];
            routes = [
              {
                match = [ { not = authorized ingress.allowedIDs; } ];
                handle = [ denied ];
              }
              {
                match = [
                  (
                    {
                      method = [ "CONNECT" ];
                    }
                    // synapse
                  )
                ];
                handle = [
                  (forwardProxy [
                    443
                    8448
                  ])
                ];
              }
              {
                match = [ { method = [ "CONNECT" ]; } ];
                handle = [ (forwardProxy [ 443 ]) ];
              }
              {
                handle = [
                  (forwardProxy [
                    80
                    443
                  ])
                ];
              }
            ];
          };
        };
      };
    in
    {
      environment.etc."realm-internet/config.json".source = configfile;
      # Caddy replaces Envoy here: the SVID and the trust bundle come from the
      # Workload API, so no certificate file exists on disk, and the forward
      # proxy resolves a destination, checks the ACL against the resolved
      # address, and then dials exactly that address.
      #
      # A separate process keeps one SPIFFE identity per process: this one may
      # only reach the public Internet on behalf of the declared callers.
      systemd.services.realm-internet = {
        wantedBy = [ "multi-user.target" ];
        # The admin endpoint is disabled, so Caddy cannot be reloaded in place: a
        # changed configuration restarts the unit instead of being silently
        # ignored until the next reboot.
        restartTriggers = [ configfile ];
        requires = [ "spire-agent.service" ];
        after = [
          "network-online.target"
          "spire-agent.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "notify";
          User = workload.user;
          Group = workload.group;
          ExecStartPre = "${caddy}/bin/caddy validate --config /etc/realm-internet/config.json";
          ExecStart = "${caddy}/bin/caddy run --config /etc/realm-internet/config.json";
          Restart = "on-failure";
          RestartSec = "3s";
          StateDirectory = "realm-internet";
          RuntimeDirectory = "realm-internet";
          RuntimeDirectoryMode = "0700";
          Environment = [
            "XDG_DATA_HOME=/var/lib/realm-internet"
            "XDG_CONFIG_HOME=/var/lib/realm-internet"
            "HOME=/var/lib/realm-internet"
          ];
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          LockPersonality = true;
          NoNewPrivileges = true;
          CapabilityBoundingSet = [ ];
          AmbientCapabilities = [ ];
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          UMask = "0027";
        };
      };
      # The gateway terminates mTLS itself and keeps host networking: it binds
      # the mesh address and must resolve and reach arbitrary public
      # destinations.
      realm.workloads.internet = {
        unit = "realm-internet.service";
        runtime = "external";
        isolation.privateNetwork = false;
        ingress.http = {
          native = true;
          port = 19328;
          service = "internet-proxy";
          allowedIDs = [
            "${config.realm.servicePrefix}misskey"
            "${config.realm.servicePrefix}grafana"
            "${config.realm.servicePrefix}immich-ml"
            "${config.realm.servicePrefix}jellyfin"
            "${config.realm.servicePrefix}vaultwarden"
            "${config.realm.servicePrefix}forgejo"
            "${config.realm.servicePrefix}ncps"
            "${config.realm.servicePrefix}synapse"
            "${config.realm.servicePrefix}calibre"
            "${config.realm.servicePrefix}mautrix-telegram"
            "${config.realm.servicePrefix}ntfy"
            "${config.realm.servicePrefix}subs"
            "${config.realm.servicePrefix}pocket-id"
          ];
        };
      };
    };
}
