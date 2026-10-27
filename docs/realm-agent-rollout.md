# Realm agent remote rollout

Validated on 2026-10-27 on branch `feat/realm-ebpf-agent`. These deployments
use normal persistent NixOS system generations, not runtime unit overrides.
Every deployed machine was rebooted and its new boot ID and running system
closure checked. Previous system generations were retained.

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

The host selection is declared in [mod/realm-agent.nix](../mod/realm-agent.nix).
uubboo is prepared there but could not be deployed: mesh SSH timed out and its
LAN address was unreachable. yidhra passed loading and attaching all nine BPF
programs in a dedicated empty cgroup; it currently has no eligible isolated
application. Its host-network gateways were not captured or rebooted.
The developer machine and laptop were excluded. eihort's existing Misskey pilot
was left in place; see [its separate validation record](realm-agent-eihort-validation.md).

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
needed. For declarative rollback, remove the host/workload from the rollout
selection (or disable its `transparent.enable`) and deploy normally.
