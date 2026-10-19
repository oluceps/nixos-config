# SPIFFE workload networking

The `realm` flake module is imported by `vxlan-mesh`. SPIRE Server runs on
eihort; mesh nodes run an Agent. Consul remains discovery-only. The trust
domain is `nyaw.xyz`, independently of the Consul DNS domain `mesh.nyaw.xyz`.

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
    consulService = "example";
    allowedIDs = [ "spiffe://nyaw.xyz/service/caddy" ];
  };
};
```

`localPort` is optional. Applications supporting Unix clients can connect
directly to `/run/realm/example/egress/loki.sock`. TCP-only applications use
the loopback adapter in their private namespace. Neither path gives the
application a route to the host or the Internet.

The generated namespace holder starts before sockets.target. systemd owns
the listening sockets; systemd-socket-proxyd bridges private loopback and
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

## SRV discovery and readiness

The egress resolves `<service>.service.mesh.nyaw.xyz` through the local
Consul DNS listener on 127.0.0.1:8600. It reads SRV priority, weight, port and
target, then resolves that target's addresses. Positive SRV records are
cached for their TTL, capped at 30 seconds. An expired cache is not used when
discovery fails. Connections try alternative endpoints before failing.

The small Python connector forwards encrypted bytes between ghostunnel and
the discovered address. ghostunnel owns the SVID and checks `verifyID`.
DNS answers cannot change the expected identity. Existing connections remain
on their selected endpoint; new connections observe discovery changes.

Only ingress addresses and ports are registered. Native TLS listeners can
also be registered once the application enforces the equivalent identity
policy. Proxies use systemd readiness notifications, so `is-active` does not
report a proxy ready while it is still waiting for its initial SVID. Consul
also checks the backend application unit. Services needing stronger readiness
should supply an application-specific startup/readiness check.

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

The ingress still presents the PostgreSQL SPIFFE identity to clients.
Dedicated accounts avoid giving a proxy the same Unix identity as the
application. Unrelated local database connections retain the general peer
rule. PostgreSQL's application TCP listener is disabled in this profile.

## Existing service profiles

The current migration covers Alloy, Loki, PostgreSQL, Atuin, Misskey, its
Redis instance, Meilisearch, SeaweedFS and Grafana. Caddy accesses migrated
backends over its own authenticated egress sockets. The legacy SeaweedFS
metrics job uses vmagent's `__unix_socket__` label to scrape through its
authenticated egress.

Caddy is an external edge workload. Squid is an external Internet gateway.
vmagent keeps its existing network access while its other monitoring targets
are migrated; its SeaweedFS egress is already authenticated. These exceptions
use `runtime = "external"` and `isolation.privateNetwork = false` explicitly.
Other repository services and VM guests have not yet received isolation
profiles. BIRD, Yggdrasil, VXLAN, DNS and Consul keep their current network
configuration.

Misskey uses rootless Podman with `network=none`. Its UID/GID 1000 maps to
the host misskey account using keep-id. A Node launcher adapts its local
PostgreSQL, Redis, Meilisearch, S3 and HTTP proxy connections to mounted egress
sockets. The application serves its native Unix socket; no host application
port is published. The container receives neither SVID keys nor the Agent
socket. The official image's tini entrypoint and migrateandstart command are
preserved. Verify the actual deployed image when upgrading the existing
`latest` tag.

Internet access uses an ordinary HTTP CONNECT proxy behind a SPIFFE ingress.
It has no domain whitelist and performs no TLS interception. Squid rejects
private, loopback, link-local and Yggdrasil destination ranges and limits
ports to 80/443. Misskey's public proxy bypasses are removed. Its only bypass
is s3.nyaw.xyz, mapped inside the container to the dedicated local adapter
through Caddy, instead of the public Internet gateway.

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
updated. The provisioned Loki source uses http://127.0.0.1:13030.

## Native certificate consumers

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
reconciliation. `tests/realm-container.nix`
checks the rootless container socket adapters with a dummy image and dummy
credentials. It does not replace checking the actual Misskey image on eihort.
