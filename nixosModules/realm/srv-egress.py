"""Resolve Consul SRV endpoints behind a ghostunnel TLS client.

The connector forwards encrypted bytes. Only ghostunnel holds an SVID and
authenticates the remote peer; discovery never decides which identity to trust.
"""

import argparse
import asyncio
import contextlib
import logging
import os
import random
import signal
import socket
import sys

import dns.asyncresolver
import dns.rdatatype


def order_records(records):
    result = []
    for priority in sorted({r.priority for r in records}):
        group = [r for r in records if r.priority == priority]
        while group:
            weights = [r.weight for r in group]
            index = (
                random.choices(range(len(group)), weights=weights)[0]
                if sum(weights)
                else random.randrange(len(group))
            )
            result.append(group.pop(index))
    return result


class Connector:
    def __init__(self, service, resolver_address, resolver_port, timeout=5):
        self.service = service
        self.resolver = dns.asyncresolver.Resolver(configure=False)
        self.resolver.nameservers = [resolver_address]
        self.resolver.port = resolver_port
        self.resolver.lifetime = timeout
        self.timeout = timeout
        self.records = []
        self.additional = {}
        self.expires = 0
        self.lock = asyncio.Lock()

    async def endpoints(self):
        async with self.lock:
            now = asyncio.get_running_loop().time()
            if now >= self.expires:
                answer = await self.resolver.resolve(self.service, "SRV")
                additional = {}
                for rrset in getattr(answer.response, "additional", ()):
                    if rrset.rdtype == dns.rdatatype.AAAA:
                        additional.setdefault(
                            (rrset.name, socket.AF_INET6), []
                        ).extend(item.address for item in rrset)
                    elif rrset.rdtype == dns.rdatatype.A:
                        additional.setdefault(
                            (rrset.name, socket.AF_INET), []
                        ).extend(item.address for item in rrset)
                self.records = list(answer)
                self.additional = additional
                self.expires = now + min(max(answer.rrset.ttl, 5), 30)
            return order_records(self.records), dict(self.additional)

    async def addresses(self, target_name, family, kind, additional):
        cached = additional.get((target_name, family))
        if cached:
            return cached
        try:
            answer = await self.resolver.resolve(target_name.to_text(), kind)
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            return []
        return [address.to_text() for address in answer]

    async def connect(self):
        records, additional = await self.endpoints()
        for record in records:
            target = record.target.to_text()
            if target == "." or record.port == 0:
                continue
            for family, kind in ((socket.AF_INET6, "AAAA"), (socket.AF_INET, "A")):
                for address in await self.addresses(
                    record.target, family, kind, additional
                ):
                    try:
                        return await asyncio.wait_for(
                            asyncio.open_connection(
                                address, record.port, family=family
                            ),
                            self.timeout,
                        )
                    except (OSError, TimeoutError):
                        continue
        self.expires = 0
        raise OSError("no reachable SRV endpoint")

    async def handle(self, reader, writer):
        remote = None
        try:
            upstream, remote = await self.connect()

            async def copy(source, destination):
                while data := await source.read(65536):
                    destination.write(data)
                    await destination.drain()
                if destination.can_write_eof() and not destination.is_closing():
                    with contextlib.suppress(OSError):
                        destination.write_eof()

            await asyncio.gather(copy(reader, remote), copy(upstream, writer))
        except (OSError, TimeoutError, dns.exception.DNSException) as error:
            logging.warning("SRV connection to %s failed: %s", self.service, error)
        finally:
            for stream in (writer, remote):
                if stream is not None:
                    stream.close()
                    with contextlib.suppress(OSError):
                        await stream.wait_closed()


async def run(args):
    if int(os.environ.get("LISTEN_FDS", "0")) != 1:
        raise RuntimeError("exactly one systemd activation socket is required")
    if int(os.environ.get("LISTEN_PID", "0")) != os.getpid():
        raise RuntimeError("activation socket belongs to a different process")

    connector = Connector(args.service, args.resolver, args.resolver_port)
    server = await asyncio.start_server(connector.handle, "127.0.0.1", 0, limit=65536)
    port = server.sockets[0].getsockname()[1]
    # The child resets LISTEN_PID before exec; FD 3 remains the app-facing socket.
    command = [sys.executable, __file__, "exec", *args.ghostunnel]
    command += ["--target", f"127.0.0.1:{port}"]
    child = await asyncio.create_subprocess_exec(*command, pass_fds=(3,))
    os.close(3)
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, lambda: child.send_signal(signal.SIGTERM))
    async with server:
        return await child.wait()


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "exec":
        os.environ["LISTEN_PID"] = str(os.getpid())
        os.execvpe(sys.argv[2], sys.argv[2:], os.environ)
    parser = argparse.ArgumentParser()
    parser.add_argument("--service", required=True)
    parser.add_argument("--resolver", default="127.0.0.1")
    parser.add_argument("--resolver-port", type=int, default=8600)
    parser.add_argument("ghostunnel", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.ghostunnel and args.ghostunnel[0] == "--":
        args.ghostunnel.pop(0)
    logging.basicConfig(level=logging.INFO)
    return asyncio.run(run(args))


if __name__ == "__main__":
    sys.exit(main())
