"""Reconcile only the SPIRE registration entries owned by this configuration."""

import json
import pathlib
import subprocess
import sys
import time
import uuid


def reconcile(binary, socket, manifest, state):
    prefix = [binary, "entry"]
    desired = json.loads(pathlib.Path(manifest).read_text())
    state = pathlib.Path(state)
    previous = json.loads(state.read_text()) if state.exists() else []
    current = []
    for node, entries in desired.items():
        for name, entry in entries.items():
            entry_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"nyaw-realm:{node}:{name}"))
            current.append(entry_id)
            exists = subprocess.run(
                prefix + ["show", "-socketPath", socket, "-entryID", entry_id],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode == 0
            args = prefix + [
                "update" if exists else "create",
                "-socketPath", socket,
                "-entryID", entry_id,
                "-parentID", entry["parentID"],
                "-spiffeID", entry["spiffeID"],
                "-x509SVIDTTL", "3600",
            ]
            for selector in entry["selectors"]:
                args += ["-selector", selector]
            subprocess.run(args, check=True, stdout=subprocess.DEVNULL)
    for entry_id in set(previous) - set(current):
        subprocess.run(
            prefix + ["delete", "-socketPath", socket, "-entryID", entry_id],
            check=True,
        )
    temporary = state.with_suffix(".tmp")
    temporary.write_text(json.dumps(current))
    temporary.replace(state)


if __name__ == "__main__":
    binary, socket, manifest, state = sys.argv[1:]
    for attempt in range(30):
        if subprocess.run(
            [binary, "healthcheck", "-socketPath", socket],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode == 0:
            break
        time.sleep(1)
    reconcile(binary, socket, manifest, state)
