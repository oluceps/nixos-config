# Realm architecture

Start with the [overview](realm-overview.svg). These diagrams show the main roles and representative connection paths from the Nix configuration.

| View | What it explains | Source |
| --- | --- | --- |
| [Overview](realm-overview.svg) | Application, gateway, backend, and identity roles | [D2](realm-overview.d2) |
| [Local transport](local-transport.svg) | Private networks, sockets, adapters, and identity checks | [D2](local-transport.d2) |
| [Configuration](config-compiler.svg) | How declarations produce system configuration | [D2](config-compiler.d2) |
| [Outbound paths](http-egress.svg) | Forgejo as an example of Internet, HTTPS, and SMTP access | [D2](http-egress.d2) |
| [Immich routing](immich-routing.svg) | Share links, the main site, and entry authentication | [D2](immich-routing.d2) |

## Connections and identities

An isolated application has its own network namespace and loopback addresses. It reaches a Unix socket directly, or uses a local TCP adapter. Ghostunnel carries the connection with mutual TLS (mTLS): both peers present certificates and check the other service's SPIFFE identity. The receiver checks its caller allowlist before it connects to the backend.

Each host has a local SPIRE Agent. The Agent checks the process unit and Unix user to select its identity. The SPIRE Server on eihort issues service certificates. Data connections travel between Realm clients and receivers.

Ordinary public Caddy uses normal HTTPS certificates. Its Ghostunnel proxies hold its Realm identity. The separate observability Caddy and Internet Envoy use SPIRE certificates and check mutual TLS themselves.

Local PostgreSQL peer authentication is a separate path. The application mounts the database socket, and PostgreSQL checks the local user.

## Configuration and access

Workload declarations describe isolation, backends, ingress, and egress. Nix combines declared identities and listeners into static catalogs. The compiler uses these catalogs to select endpoint addresses, ports, and expected identities.

The generated configuration includes systemd units, users, socket directories, SPIRE registrations, endpoint metadata, and configuration checks. Native TLS gateways have dedicated configuration generators. DNS records describe the declared addresses and ports. Endpoint selection stays fixed until the configuration changes.

Receiver allowlists grant access to Realm listeners. A gateway can select `declared-clients` admission to admit its declared clients. That admission covers the listener. `resolveHosts` supplies local aliases rather than limits on which HTTP hosts an admitted caller can request.

`NO_PROXY` changes HTTP proxy selection. Internal HTTPS aliases still use local adapters and authenticated Realm connections. SMTP uses its own declared route. Application HTTPS and SMTPS remain inside the outer Realm TLS connection.

See [the Realm reference](../docs/realm.md) for option details.

## Immich entries

Both entries use the route configuration from [caddy/immich.nix](../caddy/immich.nix). Share paths reach Immich Public Proxy (IPP).

| Entry | `/share` and `/share/*` | Other paths |
| --- | --- | --- |
| Public | IPP, without Caddy Basic Auth | Immich main site, with Caddy Basic Auth |
| Internal | IPP, without Caddy Basic Auth | Immich main site, without Caddy Basic Auth |

The main site keeps Immich's own login. Share access follows share-link permissions. IPP uses a separate Realm identity when it connects to Immich.

The entries describe listener rules. A single Caddy process can serve both entries.

## Inspect the declarations

Run these commands from the repository root:

```sh
nix eval --json .#nixosConfigurations.eihort.config.realm.authorization.matrix
nix eval --json .#nixosConfigurations.eihort.config.realm.authorization.connections
```

These queries describe configured access and connection declarations. They do not measure live traffic or health.

## Render the diagrams

Run from the repository root:

```sh
bash layout/render.sh
```

The script uses D2 from `PATH`, or gets it from the eihort Nix configuration. It uses D2's built-in fonts. Set `D2_BIN` to select another D2 executable. Set `D2_FONT` to use a custom TTF font.

After a source change, render the SVG files and inspect the text, arrows, and diagram boundaries.
