# SPIFFE workload networking

The `realm` flake module is imported by `vxlan-mesh`. SPIRE Server runs on
eihort; mesh nodes run an Agent. Each node runs a local CoreDNS discovery
listener. The trust domain is `nyaw.xyz`, independently of the discovery
DNS domain `mesh.nyaw.xyz`.

## Workload declarations

Keep declarations next to their service configuration in `mod/`. The reusable
implementation is in `nixosModules/realm-workloads.nix`; SPIRE configuration
and enrollment are in `nixosModules/realm-spire.nix`.

Migrated cluster service profiles require realm and have no legacy network
fallback. The reusable modules retain `realm.enable` as their activation
switch. Host-specific Caddy ingress and egress declarations live in
`mod/caddy/<hostname>.nix`; eihort's routes are declared in `mod/caddy/eihort.nix`.

```nix
realm.workloads.example = {
  unit = "example.service";
  user = "example";
  group = "example";

  egress.loki = {
    service = "loki";
    verifyID = "spiffe://nyaw.xyz/service/loki";
    localPort = 13030;
  };

  ingress.http = {
    port = 18080;
    target = "127.0.0.1:8080";
    privateLoopback = true;
    service = "example";
    allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
  };
};
```

`localPort` is optional. Applications supporting Unix clients can connect
directly to `/run/realm/example/egress/loki.sock`. TCP-only applications use
the loopback adapter in their private namespace. Neither path gives the
application a route to the host or the Internet.

The generated namespace holder starts before sockets.target. systemd owns
the workload-facing sockets; systemd-socket-proxyd bridges private loopback and
Unix sockets. No application needs to implement systemd socket activation.

Application units receive a private `/run` containing their egress directory,
declared runtime directories, credentials, the immutable system profile and
the systemd notification socket. Other runtime sockets are hidden. Add
necessary application runtime directories with `isolation.runtimePaths` and
additional local IPC with `isolation.allowUnixSockets`. Do not expose the
SPIRE Agent socket to an application using proxy mode.

Each workload has a separate proxy account. Its SPIRE registrations require
both the actual proxy/helper systemd unit and its Unix user. The default
SPIFFE ID is `spiffe://nyaw.xyz/service/<workload>`. Instances sharing an ID
share authorization. Root on a node remains trusted.

An ingress requires an explicit nonempty `allowedIDs` list. Declaring an
egress does not grant access at the receiver. ghostunnel enforces connection
authorization; database roles and HTTP operation/tenant authorization remain
application responsibilities.

## SRV discovery

Each discovered egress connects ghostunnel's TLS output to
`/run/realm-discovery/<workload>/<route>.sock`. The Caddy `srv_proxy` handler
resolves `<service>.svc.mesh.nyaw.xyz` through the local CoreDNS
listener on 127.0.0.1:8600. It reads SRV priority, weight, port and target,
then resolves that target's AAAA/A records through the same resolver. Lower
priorities are tried first; same-priority positive weights are selected
before zero weights, with IPv6 preferred over IPv4. Failed TCP connections
fall back to other addresses and endpoints. There is no per-route connector
process or local TCP forwarding listener.

`mod/caddy.nix` enables `realm.discovery.integrateCaddy`, merging generated
listeners into the existing `caddy.settings.apps.layer4.servers` JSON.
`pkgs.caddy-realm` retains all existing HTTP plugins and adds `srv_proxy`.
Nodes without that Caddy profile run one `realm-discovery.service`, using
`pkgs.caddy-srv` and generated JSON with its admin API disabled. A fixed
egress `target` bypasses discovery and has no dependency on either instance.

The discovered egress starts after the selected Caddy unit is ready, using
`Wants` and `After`. A Caddy restart leaves egress listeners available and
avoids socket activation cancelling the discovery daemon's stop job. Each
workload's discovery directory is owned by the Caddy user, with mode 2750
and that workload's proxy group. Unix sockets inherit this group and have
mode 0660. Applications' private `/run` does not expose discovery sockets.
Caddy only forwards TLS ciphertext; ghostunnel owns the SVID and checks
`verifyID`. Routing uses the local socket, so it does not require SNI.
DNS answers cannot change the expected identity.

SRV results are cached for `realm.discovery.refresh` (default `5s`),
independently of DNS TTL. Expired answers are not used when discovery fails;
negative answers are cached for at most one second. Complete TCP connection
failure invalidates the cache for the next attempt.
`realm.discovery.dialTimeout` (default `5s`) bounds each DNS lookup and
individual TCP attempt, rather than the total time across all endpoints.
Established connections remain on their selected endpoint; new connections
observe discovery changes. Reloading the Caddy configuration closes streams
owned by old handlers. ghostunnel accepts subsequent connections normally.

Only ingress addresses and ports are published. `mod/mesh-dns.nix` collects
`realm.serviceDiscovery.publish` from all enabled cluster configurations.
Node AAAA records come from `registry.toml` through `config.data.node`. Each
node receives a complete immutable zone with `<host>.node`, `<service>.svc`
AAAA records and SRV records targeting per-host ingress names. Multiple
instances of a service produce multiple SRV records with their own ports.
`ingress.<name>.service` names the published service; egresses keep their
existing `service` and `verifyID` declarations. Native TLS listeners are
published in the same way.

CoreDNS serves only `mesh.nyaw.xyz` on loopback UDP/TCP 8600. systemd-resolved
delegates this suffix to it; no runtime registration, gossip or quorum is
required. Zone changes take effect when the updated NixOS configuration is
deployed to each client node. Records have a five-second TTL; the Caddy SRV
cache remains independent. The zone is immutable and CoreDNS restarts with
a new Corefile when its store path changes, so no runtime SOA serial update
is needed. `/etc/coredns/mesh.zone` exposes the generated file for inspection.

Publication is independent of process health: stopped services stay in DNS.
No probes or automatic health-based record removal are included. Failed TCP
connections try other published candidates; a successful TCP connection
followed by a TLS failure does not trigger SRV fallback or request replay.
Proxies still use systemd readiness notifications while obtaining SVIDs.

Certificates have a one-hour lifetime and ghostunnel connections have a
one-hour maximum lifetime. Certificate expiry or removal of a SPIRE entry
does not immediately terminate every established connection. A policy change
that restarts an ingress also closes its connections.

## PostgreSQL peer authentication

PostgreSQL retains peer authentication and exposes its Unix socket. For each
remote consumer, a separate ingress runs as a dedicated `realm-pg-*` account.
The ingress accepts exactly that consumer's SPIFFE ID. A narrow pg_ident map
maps the local proxy account to the existing database role:

| Consumer | Ingress service | Local proxy account | SQL role |
| --- | --- | --- | --- |
| Misskey | postgresql-misskey | realm-pg-misskey | misskey |
| SeaweedFS | postgresql-seaweedfs | realm-pg-seaweedfs | seaweed |
| Atuin | postgresql-atuin | realm-pg-atuin | atuin |
| Immich | postgresql-immich | realm-pg-immich | immich |
| Autopeer | postgresql-autopeer | realm-pg-autopeer | dn42 |

The ingress still presents the PostgreSQL SPIFFE identity to clients.
Dedicated accounts avoid giving a proxy the same Unix identity as the
application. Unrelated local database connections retain the general peer
rule. Its workload explicitly sets `isolation.privateNetwork = false`, while
the private runtime socket view is retained. Host-local TCP clients retain
SCRAM-SHA-256 access through 127.0.0.1 and ::1; Unix sockets keep peer
authentication.

## Existing service profiles

The current migration covers Alloy, Loki, PostgreSQL, Atuin, Misskey, its
Redis instance, Meilisearch, SeaweedFS, Grafana and Immich (including Redis,
machine learning and public proxy). Caddy accesses migrated
backends over its own authenticated egress sockets. The legacy SeaweedFS
metrics job uses vmagent's `__unix_socket__` label to scrape through its
authenticated egress.

Caddy is a systemd edge workload with host networking and a private `/run`
view. Its management API listens on `/run/caddy/admin.sock` (0600), inside a
0700 directory. Only its own egress directories, discovery listeners, runtime
directory and DNS resolver sockets are exposed. Envoy is an external Internet gateway.
vmagent keeps its existing network access while its other monitoring targets
are migrated; its SeaweedFS egress is already authenticated. These exceptions
use `isolation.privateNetwork = false` explicitly; Envoy and vmagent also use
`runtime = "external"`.
Services without migration profiles and VM guests keep their previous isolation.
BIRD, Yggdrasil and VXLAN keep their current network configuration.
The existing recursive DNS module is separate from mesh discovery.

Public entrypoints (abhoth, nodens and azasos) import
`mod/caddy/public.nix`. Shared HTTP routes use Caddy's authenticated Unix
egress sockets, with SRV discovery and fixed remote SPIFFE IDs. Legacy routes
for seed, Pocket ID, Memos, Alertmanager and heartrate cross the mesh through
eihort's separately authorized `internal-https` ingress (19444); their final
legacy backend connections are unchanged. The existing `s3-https` ingress
keeps its application allowlist. The zone apex reaches Misskey directly via
its own ingress and still serves Matrix discovery responses.

Yidhra has fixed 457 MiB memory and uses a smaller edge profile: local TLS
and Autopeer remain, while shared Web routes use one authenticated
`public-http` egress. Eihort serves that public route set on a separate
Unix socket behind ingress 19445. It preserves public route authentication
and trusts forwarded client headers only on that protected Unix listener.
Unknown hostnames receive 404. Yidhra sets Go memory tuning to a 48 MiB
soft limit and GOGC=50; these are not a hard process memory limit.

Rustypaste, ntfy and subs run in private loopback namespaces. Their business
ingresses allow only Caddy. ntfy's metrics use a separate ingress authorizing
only the local observation gateway. ntfy and subs fetch public HTTP(S)
resources through the authenticated Internet gateway. Subs uses a dedicated
account and receives its secret script via `LoadCredential`, rather than
running as the administrator.

Autopeer retains host netlink/WireGuard access and its PostgreSQL egress. Its
node-specific HTTP ingress authorizes Caddy; nftables rejects non-loopback
connections to the original API port. Stalwart retains public mail networking,
but its Web API is exposed through the authenticated `stalwart-web` listener
on the observation gateway. That business listener rejects metrics/debug paths.
Public Caddy nodes without a local Rustypaste or Stalwart use their advertised
ingresses, rather than stale localhost routes. Xray and Hysteria retain their
gateway networking with process/filesystem sandboxes; a normal Hysteria server
no longer receives NET_ADMIN, NET_RAW, BPF or PERFMON capabilities, or realtime
CPU priority.

Misskey uses rootless Podman with `network=none`. Its UID/GID 1000 maps to
the host misskey account using keep-id. A Node launcher adapts its local
PostgreSQL, Redis, Meilisearch, S3 and HTTP proxy connections to mounted egress
sockets. The application serves its native Unix socket; no host application
port is published. The container receives neither SVID keys nor the Agent
socket. The official image's tini entrypoint and migrateandstart command are
preserved. Verify the actual deployed image when upgrading the existing
`latest` tag.

Immich uses separate private namespaces for `immich-server`, `redis-immich`,
`immich-machine-learning` and `immich-public-proxy`. The server connects to
PostgreSQL on 127.0.0.1:15432, Redis on 127.0.0.1:6379 and ML on
127.0.0.1:3003 through its authenticated egress adapters. ML runs as the
separate `immich-ml` user; its HTTP/HTTPS proxy on 127.0.0.1:13128 reaches the
Internet gateway under the ML SPIFFE identity. Xet downloads are disabled;
verify model downloading and inference with the installed model versions.

Immich retains `settings = null`. Before deployment, set its persisted
`machineLearning.urls` setting to `[ "http://127.0.0.1:3003" ]` through the
administration UI. Do not rely on `IMMICH_MACHINE_LEARNING_URL` alone.
`photo.nyaw.xyz` routes through Caddy's public proxy egress; the public proxy
connects to its own 127.0.0.1:2283 adapter. The full Immich server remains
available through its mesh ingress rather than this public hostname.
Its existing Vaultix file contains only a database password and is unchanged;
the peer authentication path does not use that password. SMTP, OAuth and
other optional server-side network integrations require separate egress
declarations when enabled. Check database extension upgrades and backup
privileges separately from the SPIFFE/peer authentication path.

Internet access uses Envoy's HTTP dynamic forward proxy and CONNECT
termination. Envoy is the native SPIFFE ingress on port 19328, registered as
`internet-proxy`; there is no separate gateway ghostunnel or plaintext proxy
listener. The clients' local proxy addresses remain unchanged. Envoy obtains
its SVID and trust bundle directly from the SPIRE Agent over SDS and requires
a client certificate with one of the ingress's exact `allowedIDs` URI SANs.

The gateway has no domain whitelist and performs no application TLS
interception. Downstream RBAC checks the resolved IP and port, and upstream
RBAC rechecks the selected address before connecting. Both use default-deny
rules permitting public HTTP on ports 80/443 and CONNECT only on port 443.
Private, loopback, link-local, IPv4-mapped IPv6 and Yggdrasil destinations are
denied, including names resolving into those ranges. The Envoy listener
becomes active after its SDS credentials arrive; DNS publication does not
wait for this readiness. Misskey's public proxy bypasses are removed. Its only bypass
is s3.nyaw.xyz, mapped inside the container to the dedicated local adapter
through Caddy, instead of the public Internet gateway.

`mod/overlay.nix` exports `overlays.envoy` and applies it to hosts importing
the overlay module. It pins the official Envoy 1.40.0 release binaries and
SHA-256 digests for x86_64-linux and aarch64-linux, with their ELF dependencies
patched for NixOS. This avoids reusing the older nixpkgs Bazel WORKSPACE
packaging for the release's bzlmod build.

## Vaultix

Loki and Misskey read complete configurations from Vaultix without a runtime
merge step. Update their decrypted YAML with the networking settings below,
then re-encrypt it into `sec/loki.age` and `sec/misskey.age` before deployment.
Local working copies in `plaintext-secret/` are ignored by Git and must stay
outside the Nix store. Credentials and unrelated settings are preserved.

For Loki, set `server.http_listen_address` and
`server.grpc_listen_address` to 127.0.0.1, and set
`common.storage.s3.endpoint` to 127.0.0.1:18333 with `insecure=true`. That
local plaintext hop is protected by the private namespace; inter-node
transport remains authenticated TLS. The S3 keys, bucket and region remain
in the encrypted secret. systemd passes the complete file through
`LoadCredential`; Loki reads `/run/credentials/loki.service/config`.

For Misskey, select the native Unix listener `/realm/backend/http.sock` and
mode 0660, remove the TCP port, change database/cache/search hosts to loopback
adapters, set `proxy=http://127.0.0.1:13128`, restrict `proxyBypassHosts` to
s3.nyaw.xyz, and limit
`allowedPrivateNetworks` to loopback. Database and search credentials remain
in Vaultix. With keep-id, Misskey's source secret can use mode 0400 instead
of 0444. Podman mounts this file read-only as `/misskey/.config/default.yml`.

Grafana's secret key and SeaweedFS's S3 configuration use systemd credentials.
Existing Grafana data sources saved in its database may need their URLs
updated. The provisioned Loki source uses http://127.0.0.1:13030. The
provisioned VictoriaMetrics source uses http://127.0.0.1:13090, which reaches
an authenticated API listener rather than the plaintext mesh port.
Grafana itself uses its local PostgreSQL peer socket. systemd unsets the legacy
`GF_DATABASE_URL` from its environment file so it cannot override that socket configuration;
the other secret environment settings remain available. Loki's instance, memberlist
and frontend addresses are explicitly loopback, avoiding host interface discovery.

## Native certificate consumers

An application implementing SPIFFE TLS itself can declare
`ingress.<name>.native = true`, omitting the proxy `target`. The module binds
the workload's SPIRE registration to its application unit and Unix user,
grants access to the Agent socket, and publishes its ingress in the generated DNS zone.
The application must configure its own listener, consume SDS updates and
enforce the declared `allowedIDs`; the Envoy gateway reads those declarations
directly. Native ingress currently requires a host-networked application.
Applications without SDS support can instead use the helper below.

```nix
realm.workloads.native = {
  isolation.privateNetwork = false;
  credentials.enable = true;
};
```

This produces `svid.pem`, `key.pem` and `bundle.pem` under
`/run/realm/native/credentials`. The helper owns the files; the application
group can read the private key with mode 0640. The application starts after
the initial certificate has been written. The helper watches renewal events.

This is only a credential adapter. The application must verify SPIFFE URI
identities, enforce its caller policy and reload both identity and trust
bundle. Merely supporting PEM certificates is insufficient. Applications
watching certificate files can use the default helper configuration;
`credentials.settings` exposes upstream helper settings for other reload
mechanisms. Commands run as the helper account; a reload command may need
narrow permission to signal or reload its application. Direct network access
in this mode is an explicit exception to proxy isolation.

## Initial enrollment and deployment

See [the first deployment runbook](realm-deployment.md) for the host order,
bootstrap commands, secret prerequisites and application checks.

The SPIRE signing keys and datastore are persisted under /var/lib/spire;
enrollment material is root-only under /var/lib/realm-spire. Include these
paths in the host's normal persistence and backup strategy. Neither belongs
in Git or the Nix store.

Deploy eihort first so the Server and registration reconciler exist. Initial
workload starts can fail until the Agent is enrolled. Enrollment is carried
over the existing root SSH trust boundary:

```sh
ssh root@eihort realm-enroll eihort | ssh root@eihort realm-install-enrollment
ssh root@eihort realm-enroll abhoth | ssh root@abhoth realm-install-enrollment
```

Each command issues a short-lived, single-use token and transfers the public
trust bundle directly to its destination. Do not print or save the enrollment
JSON in a public log. Enroll each deployed mesh node and restart any failed
workload units. Registration entries are generated from workload declarations
across hosts, reconciled idempotently and pruned only from the reconciler's
own managed set.

Agent keys survive a restart. If an Agent's cached node identity expires
while it is offline, join-token attestation requires fresh enrollment. The
enrollment tools are administrative commands, not workload capabilities.

## Verification

`tests/realm-workloads.nix` checks evaluation and policy wiring.
`tests/realm-vm.nix` checks actual SPIRE enrollment, SRV discovery, authorized
and rejected mTLS peers, PostgreSQL peer authentication, socket isolation,
helper key access, Internet proxy destination restrictions and registration
reconciliation. `tests/realm-immich.nix` imports the actual Immich, PostgreSQL
and Internet gateway profiles with fixture application processes, real
PostgreSQL/Redis and real SPIRE. It checks dependency forwarding, peer role
isolation, rejected SPIFFE callers, ML gateway authorization and private
runtime/network boundaries. It does not exercise Immich's actual migrations,
model downloads or inference. `tests/realm-container.nix`
checks the rootless container socket adapters with a dummy image and dummy
credentials. It does not replace checking the actual Misskey image on eihort.

## Application profiles and observation endpoints

Synapse and mautrix-telegram have separate private network namespaces. The
bridge's homeserver requests and Synapse's appservice callbacks use independent
SPIFFE routes. Both retain local PostgreSQL Unix peer authentication. Synapse's
S3 backend and scheduled uploader use authenticated SeaweedFS routes. Calibre
accepts requests only from Caddy's SPIFFE identity.

Mautrix Telegram MTProto connections use a private SOCKS5 adapter, chained to
that workload's authenticated HTTP Internet egress. `socksProxy.enable` adds
this adapter for applications requiring SOCKS; container workloads receive it
through an additional protected Unix socket. UDP and SOCKS BIND are disabled.
The gateway permits public HTTP/HTTPS destinations; only the Synapse identity
also receives CONNECT access to public port 8448 for federation. Federation
servers advertising other custom ports require an explicit gateway policy.

Telegram Search is enabled on eihort as a rootless `network=none` container.
Its frontend publishes a Unix socket to Caddy; database access uses a dedicated
PostgreSQL ingress and peer role mapping. S3 TLS is preserved through Caddy's
S3 ingress. GramJS uses the SOCKS adapter; Node HTTP requests use environment
proxy support. The image's nginx worker setup retains CHOWN/SETUID/SETGID only
inside the rootless user namespace. Its nginx state/log directories use disposable
tmpfs mounts with `notmpcopyup`, so restrictive ownership from the image is not copied
into those mounts and no DAC override capability is needed. Existing `/var/lib/tg-search` data ownership
is migrated once to the rootless service account. The existing upstream
`latest` image tag is retained; fixture tests do not validate a future image's
layout or behavior. ARTEX and Magpie are outside this migration.

Each exporter declares its endpoint next to its service via
`realm.observability.endpoints`. Envoy publishes one mTLS observation ingress
per host, with a host-specific SPIFFE identity and a vmagent caller allowlist.
CoreDNS advertises that ingress. Vmagent uses protected Unix egress sockets,
validates the expected host identity, and requests only `/NAME/metrics` or the
explicitly configured `/NAME/probe` routes. Business and debug paths, metrics
query parameters, and non-GET methods are rejected. Blackbox probe module and
target pairs are enumerated from the configured jobs; extra and duplicate
parameters are rejected. Redirects are disabled for HTTP probes.

Exporter listeners bind loopback where supported. An input firewall rule
additionally blocks external access to backend metric ports. NCPS runs in a
private namespace; its cache ingress accepts only the Nix cache client identity.
Its metrics use a separate observation-only ingress. The previous plaintext
port 8501 is no longer exposed. VictoriaMetrics keeps
a filtered Envoy listener for its existing query/write port;
those business APIs retain their previous mesh access policy. It also publishes
an authenticated API listener. That listener rejects metrics/debug paths,
preserves other business paths and methods, and admits only the identities in
`businessAllowedIDs`; Grafana queries it through a protected Unix egress socket.
Both listeners are separate ports, so the plaintext business port keeps its
path restrictions. Vmagent and
vmalert HTTP listeners bind loopback. Alertmanager HTTP binds loopback and its
public Caddy route excludes metrics/debug paths; cluster gossip is unchanged.
Stalwart's public Caddy route also excludes its metrics/debug paths. Synapse
metrics traverse a dedicated authenticated ingress after leaving its private
namespace. Sept guest exporters use the host observation ingress, with the
final connection confined to the existing guest bridge. Node and chrony
exporters keep host visibility; infrastructure daemon networking is unchanged.

`tests/realm-vm.nix` also tests the SOCKS chain, Synapse-specific federation
permission, observation identity checks, path/query restrictions, blackbox
allowlists, the shared business listener, the authenticated API listener with
its caller allowlist, and direct backend firewall denial.
`tests/realm-container.nix` imports both actual Misskey and Telegram Search
profiles with a fixture image, including the latter's TCP-to-Unix ingress,
rootless mapping, environment override, and health check.


Jellyfin, Vaultwarden, Forgejo and NCPS are isolated workloads declared in their
own `mod/` service profiles. Caddy reaches the application HTTP backends through Unix
mTLS egress sockets; NCPS instead accepts the dedicated Nix cache client. Their public Internet requests use the authenticated
Envoy gateway; Forgejo explicitly enables its application proxy and also sets
libcurl proxy variables for Git subprocesses. Jellyfin media paths and device
permissions are preserved; LAN discovery and direct media ports do not cross
its private network namespace.

Forgejo and NCPS retain their local PostgreSQL peer sockets. Vaultwarden's
existing database URL remains valid inside its namespace through a dedicated
PostgreSQL ingress, whose operating-system account maps only to database role
`vault` in database `vaultwarden`. Presenting the old password cannot select
another database role through that ingress. Existing PostgreSQL mesh TCP
compatibility remains unchanged.

SMTP for Forgejo and Vaultwarden uses Stalwart's SPIFFE-authenticated
`smtp-submission` ingress. S3 for Forgejo and NCPS uses Caddy's authenticated
S3 ingress. Workload-local `/etc/hosts` aliases direct the original SMTP/S3
hostnames to the local adapters, preserving application TLS verification and
SNI. These aliases do not change host-wide DNS. Applications needing DNS also use
`isolation.dns`: a namespace-local UDP/TCP stub forwards DNS-over-TCP through a
protected Unix socket to the existing host systemd-resolved stub. The host-side
adapter can reach only loopback, and clients cannot choose its upstream. This
preserves DNS-dependent URL checks while granting no direct network route;
existing DNS infrastructure and upstream selection are unchanged. No secret
values need changing.
Stalwart keeps its public mail edge networking. The existing Forgejo Actions
runner remains a separate execution boundary with its existing container
runtime access; the Forgejo daemon's private namespace does not isolate CI
jobs or remove runner privileges.

`tests/realm-services.nix` runs the actual Jellyfin, Vaultwarden, Forgejo and
NCPS executables with real PostgreSQL, SPIRE and Envoy. Local SMTP/S3 fixtures
supply dummy credentials and certificates. It checks application startup,
authenticated ingress, SMTP/S3 certificate names, PostgreSQL role isolation,
NCPS observation, FFmpeg proxy requests, scoped UDP/TCP DNS, hidden runtime sockets and blocked direct network access.
It does not exercise real SMTP delivery, S3 durability or CI jobs.


The `ncps-client` module is wired into realm hosts. It exposes only a loopback
adapter at `http://127.0.0.1:18502`, permitting GET/HEAD cache reads and rejecting
metrics/debug paths. It forwards to NCPS with the `nix-cache`
SPIFFE identity. NCPS has no new public Caddy route and its old mesh plaintext
port remains closed. Nix substituter use remains opt-in (the existing commented
entry in `mod/nix.nix` now points to this adapter). This grants Nix a cache
capability without changing the Nix daemon's host infrastructure permissions.
