"""Test generated business HTTP filters against a disposable local backend.

Arguments: generated Envoy JSON, envoy executable. This exercises HTTP policy;
SPIFFE authentication is covered separately by realm-vm.nix.
"""

import copy
import http.client
import http.server
import json
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time


class Backend(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"fixture")

    do_POST = do_GET

    def log_message(self, *_):
        pass


source = json.loads(Path(sys.argv[1]).read_text())
listener = copy.deepcopy(next(
    item for item in source["static_resources"]["listeners"]
    if item["name"] == "observe_forward_stalwart"
))
# Test only the generated HTTP filter; no real Agent or production upstreams.
listener["filter_chains"][0].pop("transport_socket")
with socket.socket() as reservation:
    reservation.bind(("127.0.0.1", 0))
    port = reservation.getsockname()[1]
listener["address"]["socket_address"] = {"address": "127.0.0.1", "port_value": port}
backend = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Backend)
threading.Thread(target=backend.serve_forever, daemon=True).start()
fixture = {"static_resources": {
    "listeners": [listener],
    "clusters": [{
        "name": "observe_stalwart", "type": "STATIC", "connect_timeout": "1s",
        "load_assignment": {"cluster_name": "observe_stalwart", "endpoints": [{
            "lb_endpoints": [{"endpoint": {"address": {"socket_address": {
                "address": "127.0.0.1", "port_value": backend.server_port,
            }}}}],
        }]},
    }],
}}


def request(path, method="GET"):
    connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
    try:
        connection.request(method, path)
        response = connection.getresponse()
        response.read()
        return response.status
    finally:
        connection.close()


with tempfile.TemporaryDirectory(prefix="realm-edge-http-") as directory:
    config = Path(directory) / "envoy.json"
    config.write_text(json.dumps(fixture))
    with (Path(directory) / "envoy.log").open("w+") as log:
        process = subprocess.Popen([
            sys.argv[2], "-c", str(config), "--disable-hot-restart", "--concurrency", "1",
        ], stdout=log, stderr=log)
        try:
            for _ in range(100):
                if process.poll() is not None:
                    log.seek(0)
                    raise AssertionError(log.read())
                try:
                    if request("/api/v1/query?query=up") == 200:
                        break
                except OSError:
                    pass
                time.sleep(0.05)
            else:
                raise AssertionError("Envoy did not become ready")
            assert request("/jmap/session") == 200
            assert request("/jmap", "POST") == 200
            for path in [
                "/metrics", "/metrics/prometheus", "/metrics/otel",
                "/metrics/prometheus?format=text", "/metrics/prometheus/extra",
                "/%6detrics/prometheus", "//metrics/prometheus", "/a/../metrics/prometheus",
                "/a/%2e%2e/metrics/prometheus", "/debug/pprof", "/debug?x=1",
            ]:
                assert request(path) == 403, path
                assert request(path, "POST") == 403, path
            for path in ["/metrics%2fprometheus", "/metrics%2Fprometheus", "/metrics%5cprometheus"]:
                assert request(path) in [400, 403], path
            print("PASS: business GET/POST work; metrics/debug and encoded bypass paths are blocked")
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            backend.shutdown()
            backend.server_close()
