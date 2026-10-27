# Realm agent remote rollout

Validated on 2026-10-27 on branch `feat/realm-ebpf-agent`. Deployments use
normal persistent NixOS generations. Previous generations were retained.

## Automatic enrollment

The per-host service whitelist has been removed. The reusable module defaults
to capturing enabled, private-network systemd workloads and supported rootless
containers. Host-network gateways and external runtimes stay outside capture.
`mod/realm-agent.nix` now only opts the developer machines hastur and kaambl out.
New workloads on enabled hosts do not need another enrollment entry.

A unique declared `internet-proxy` egress supplies the Internet route, including
manually declared egresses such as Misskey's. No matching route, or several
ambiguous matches, defaults to no public TCP or external DNS. An explicit
`internetRoute` selects an existing route; explicit `null` disables it.
Synapse retains its existing 443/8448 client ports and receiver-side policy.

| Host | Automatically enrolled | Latest validation |
| --- | --- | --- |
| eihort | 22 declarations: 21 continuously running workloads and the scheduled Synapse uploader | Full reboot, all 20 native daemon probes passed, Misskey avatar regression passed |
| azasos | alloy, ntfy, subs | Persistent switch, DNS/TCP policy and application health passed |
| abhoth | alloy, rustypaste | Persistent switch, DNS/TCP policy and application health passed |
| nodens | alloy | ARM native build and persistent switch, DNS/TCP policy and application health passed |

Native gates now require the configured **system unit**, in addition to the
numeric UID. Slice ancestors are allowed; user-manager units and names nested
inside another delegated service are rejected. The unit's complete cgroup is
captured, including a gate's `.control` subgroup. This separates gate requests
from Synapse and its uploader despite their shared Unix UID; it does not turn
that UID into two distinct Linux security principals. Rootless containers still
require a workload-exclusive UID. Both Nix and runtime account checks reject
unsupported sharing.

The x86_64 and ARM64 integration fixtures refused a gate from a different unit
running under the correct UID. Their DNS/TCP, concurrent resolver, half-close,
private-address denial, worker crash and controller restart checks all passed.
Module tests cover automatic eligibility, per-workload and per-host opt-out,
Internet route inference, ambiguous routes, and proxy environment fallback.

On eihort, the new boot ID was
`32293267-60f0-4c6c-af07-1991ae857a89`. The expected persistent generation and
agent/PostgreSQL/Redis/Misskey units were ready 143.3 seconds after the reboot
request. The 20 native daemon probes then passed inside their actual cgroups
and namespaces. Services with Internet egress resolved DNS and fetched HTTPS
without proxy environment variables; other services returned DNS REFUSED and
closed public TCP connections. The scheduled uploader was not manually invoked.

Both production Misskey avatar paths returned HTTP 200: the original S3 avatar
was WebP / 20,168 bytes, and the GitHub avatar was WebP / 3,032 bytes. A subsequent
controlled agent restart recovered 21 running cgroup/namespace pairs in about
1.3 seconds, with all 21 application main PIDs unchanged and no failed units.
The agent cgroup used approximately 111 MiB after this restart; this is a sample,
not a capacity guarantee.

### Pilot migration edge cases

The first eihort hot switch updated unit files but retained the old pilot agent
process with its one-workload configuration. New native gates consequently
waited for absent control sockets; some units exhausted startup limits, and
some bind mounts failed before the new control directories existed. Explicitly
restarting the agent loaded all 22 declarations. Resetting the affected units
and sockets restored them. The later full boot needed none of those repairs.
For migration from runtime overrides, stop the old pilot before the switch or
perform a controlled boot into the new generation; replacing unit files alone
is insufficient evidence that the old process has gone away.

The first hot switch also left PostgreSQL's old process running without the new
gate, despite listing the unit for stop/start. Its declared restart/stop policy
was enabled; the precise activation race was not isolated. A full reboot ran its
gate, and both its capture log and its DNS/TCP policy probe passed. Check actual
PIDs and captured state when first enrolling existing services.

## Initial rollout and reboot baseline

The earlier whitelist deployment rebooted azasos, abhoth and nodens, checking
new boot IDs and running system generations. These results precede automatic
enrollment and the native unit binding above.

| Host | Architecture / kernel | Captured workloads | Policy | Reboot result |
| --- | --- | --- | --- | --- |
| azasos | x86_64 / 7.3.0 | subs, ntfy | Existing SPIFFE Internet egress, TCP 443 | DNS, HTTPS and ntfy health passed |
| abhoth | x86_64 / 7.3.0 | alloy, rustypaste | Existing declared peers only; no public Internet | DNS REFUSED, public TCP denied, application health passed |
| nodens | aarch64 / 7.3.0 | alloy | Existing declared peers only; no public Internet | DNS REFUSED, public TCP denied, application health passed |

All three finished with the agent, SPIRE agent, Internet gateway and application
units active, no failed units, and no agent error-level entries in the final
boot. Public HTTPS probes explicitly disabled proxy settings. The probe child
joined the actual application's cgroup and network namespace, then dropped to
its UID/GID before opening sockets.

uubboo inherits automatic enrollment but could not be deployed: mesh SSH timed out and its
LAN address was unreachable. yidhra passed loading and attaching all nine BPF
programs in a dedicated empty cgroup; it currently has no eligible isolated
application. Its host-network gateways were not captured or rebooted.
The developer machine and laptop were excluded. The earlier Misskey pilot is
recorded [separately](realm-agent-eihort-validation.md); eihort now uses the
persistent automatic configuration described above.

## Compatibility fixes

1. **Implicit DynamicUser names.** ntfy omits `User=` and systemd derives
   `ntfy-sh` from the unit name. The module now recognizes that effective user.
   Realm still declares the account statically, and the controller continues
   to require its actual numeric UID. Wrong explicit users remain rejected.
2. **Kernel fallback tunnels.** Loading tunnel modules creates `ip6tnl0`,
   `gre0`, `gretap0` and `erspan0` inside new namespaces. abhoth had all four;
   nodens had `ip6tnl0`. These initially caused readiness refusal. They are now
   accepted only with the expected name/kind pair, the kernel's
   namespace-immutable flag, admin DOWN, no endpoints, no addresses and no
   routes. The application and worker have no CAP_NET_ADMIN. Configured or
   operational tunnels remain rejected; no default route is permitted.

The final x86_64 and ARM64 packages passed the remote fixture's IPv4/IPv6 DNS,
resolver source/peer restoration, eight simultaneous resolver peers and overflow
rejection, TCP DNS, 128 concurrent TCP forwards, half-close, private-address and
unsupported UDP denial, worker crash recovery, and controller restart recovery.
The azasos fixture also fetched public HTTPS over its existing SPIFFE egress.
A production agent crash on azasos recovered both workloads without changing
either application's main PID.
After the nodes settled, Alloy on abhoth and nodens also fetched HTTP 200 from
Loki's `/ready` through their existing `127.0.0.1:13030` adapters and authenticated
cross-node egress. The original declared-peer path remained usable.

## Startup observations

`active` is not equivalent to an application HTTP listener being ready. After
reboot, Alloy briefly refused connections on its health port despite the unit
already being active. Bounded retries then obtained HTTP 200. The agent's gate
signals local socket-adapter readiness; it does not assert application health.

The final reboot measurements, from reboot request, were:

| Host | SSH and application units active | All application probes passed |
| --- | ---: | ---: |
| azasos | 75.9 s | 355.9 s |
| abhoth | 84.5 s | 105.1 s |
| nodens | 47.1 s | 57.3 s |

These are individual observations, not startup guarantees. azasos temporarily
returned DNS SERVFAIL because SPIRE could not connect to `[fdcc::3]:8081` while
mesh connectivity recovered; its Internet gateway was not yet ready. After the
mesh and SPIRE recovered, the same applications and agent passed DNS and HTTPS
without a manual restart. No direct-network fallback was introduced.

The existing VXLAN configuration uses random IPv6 link-local addresses. azasos's
link-local changed across reboots while its MAC stayed constant; eihort showed
both old neighbor entries and the new Babel next hop. This is a candidate
for a separate routing-startup improvement; this rollout did not change the
fabric's address-generation or routing policy. Keep a public SSH path available
when testing reboots instead of treating temporary mesh unreachability as a
failed host boot.

## Reproduce

Run only on authorized remote hosts; these scripts manipulate test cgroups or
join existing service namespaces.

```sh
python3 tests/realm-agent-integration.py /path/to/realm-agent \
  --user subs --internet
python3 tests/realm-agent-integration.py /path/to/realm-agent --user alloy
python3 tests/realm-agent-live.py subs.service --internet
python3 tests/realm-agent-live.py ntfy-sh.service --internet \
  --unix /run/ntfy-sh/http.sock
python3 tests/realm-agent-live.py alloy.service \
  --http http://127.0.0.1:12345/-/ready
```

The integration fixture uses a separate PrivateNetwork unit and accepts explicit
user/group/worker account and Internet socket arguments. It fails promptly if
the fixture exits before readiness. The live probe does not modify application
data, read credential files or output environment values; it checks only
proxy-variable names. Re-upload disposable `/tmp` probes after a reboot.

For rollback, activate the retained previous system generation and reboot if
needed. For declarative rollback, set `realm.agent.enable = false` on the host or
`realm.workloads.<name>.transparent.enable = false` for a workload, then deploy
normally.
