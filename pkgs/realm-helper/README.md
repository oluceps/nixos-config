# realm-helper

Small static binary that does the user-space work a realm workload cannot do
without a network route. Standard library only, `CGO_ENABLED=0`, so the same
artifact runs in a hardened systemd sandbox and inside arbitrary container
images.

```text
realm-helper dns    --upstream SOCKET     UDP/TCP 127.0.0.53:53 -> DNS-over-TCP on a Unix socket
realm-helper bridge --target ADDRESS      socket-activated listener -> TCP address or Unix socket
realm-helper launch COMMAND [ARG...]      container entrypoint adapter
realm-helper spire-register ...           reconcile SPIRE registrations
realm-helper enroll NODE                  issue a join token and trust bundle
realm-helper install-enrollment           consume that JSON on the target node
```

## dns

Used by `realm.workloads.<name>.isolation.dns`. The workload namespace has no
route out, and `systemd-socket-proxyd` cannot carry datagrams, so one process
owns both DNS transports inside the namespace:

```text
application --UDP/TCP 127.0.0.53:53--> realm-helper dns
                                        └--(length-prefixed frames)--> /run/realm/<name>/egress/dns.sock
                                                                       --> host adapter --> systemd-resolved
```

Behaviour worth knowing:

- a UDP answer larger than the client's advertised EDNS0 payload size (or 512
  bytes without EDNS0) is replaced by a header-only answer with TC set, so the
  resolver retries over TCP — which this same process serves;
- answers whose ID or question does not match the query are rejected, and an
  unreachable upstream becomes `SERVFAIL`, never a silent drop;
- at most 32 UDP queries are in flight; beyond that new datagrams are dropped
  and the client's retry takes over;
- the sockets come from systemd (`FileDescriptorName=dns-udp` / `dns-tcp`), so
  the helper never binds a privileged port itself.

## bridge

Replaces a `systemd-socket-proxyd` instance where the target is a
workload-private loopback address (the container SOCKS adapter) — same job, one
fewer binary in the closure.

## launch

`launch` runs inside the container as the entrypoint:

- every entry of `/realm/routes.json` becomes a loopback listener that pipes to
  a mounted egress Unix socket (TCP-only clients never see the socket);
- `REALM_INGRESS_PORT`, when set, publishes `/realm/backend/http.sock` for an
  application that serves TCP but cannot create its own Unix listener;
- the real command runs as a child; the helper forwards termination signals,
  reaps orphans (it may be PID 1) and exits with the child's status.

## spire-register

Runs on the SPIRE server host as a oneshot with `restartTriggers`, so a deployed
configuration re-applies the declaration once instead of polling:

```text
manifest (node -> entry) --create/update--> spire-server
state file (IDs created last time) --prune--> entries removed from the manifest
```

Entry IDs are UUIDv5 of `nyaw-realm:<node>:<name>`, deliberately identical to
the Python implementation this replaced: existing registrations keep their IDs,
so a deployment updates in place instead of creating a second set. Entries that
were never created by this command are never deleted.

## enroll / install-enrollment

The two halves of node enrollment, joined by a pipe over the existing root SSH
trust boundary:

```sh
ssh root@eihort realm-enroll abhoth | ssh root@abhoth realm-install-enrollment
```

`enroll` validates the node against the manifest keys, asks the server for a
single-use token (`-ttl 600`) and prints `{node, token, bundle}` on stdout only.
`install-enrollment` refuses to run unprivileged or for another hostname, writes
`join-token` and `trust-bundle.pem` into `/var/lib/realm-spire` with
`O_NOFOLLOW`/0600, then restarts `spire-agent`.

## Development

```sh
cd pkgs/realm-helper
go test -race ./...
```

The tests use real sockets: a Unix-socket upstream, ephemeral UDP/TCP listeners,
and a temporary `routes.json`, so the protocol behaviour (truncation, SERVFAIL,
pipelining, socket bridging, exit-status propagation) is exercised without a VM.
