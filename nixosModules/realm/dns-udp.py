"""Private UDP DNS stub; its only upstream capability is a fixed Unix socket."""
import concurrent.futures
import socket
import struct
import sys
import threading

import dns.message
import dns.rcode

listener = socket.socket(fileno=3)
slots = threading.BoundedSemaphore(32)


def receive(stream, count):
    result = bytearray()
    while len(result) < count:
        data = stream.recv(count - len(result))
        if not data:
            raise ConnectionError("DNS upstream closed")
        result.extend(data)
    return bytes(result)


def answer(wire, client):
    try:
        query = dns.message.from_wire(wire)
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as upstream:
                upstream.settimeout(5)
                upstream.connect(sys.argv[1])
                upstream.sendall(struct.pack("!H", len(wire)) + wire)
                size = struct.unpack("!H", receive(upstream, 2))[0]
                response = dns.message.from_wire(receive(upstream, size))
                if not query.is_response(response):
                    raise ValueError("DNS response does not match query")
        except (OSError, ValueError):
            response = dns.message.make_response(query)
            response.set_rcode(dns.rcode.SERVFAIL)
        listener.sendto(response.to_wire(max_size=max(512, min(query.payload, 4096)), prefer_truncation=True), client)
    except (OSError, dns.exception.DNSException):
        pass
    finally:
        slots.release()


with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
    while True:
        wire, client = listener.recvfrom(65535)
        if slots.acquire(blocking=False):
            pool.submit(answer, wire, client)
