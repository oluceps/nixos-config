package main

import (
	"encoding/binary"
	"net"
	"path/filepath"
	"testing"
	"time"
)

// fixture builds DNS messages the same way a resolver would, without pulling in
// a DNS library: stdlib-only is a design goal for this helper.
func buildQuery(id uint16, name string, payload int) []byte {
	message := make([]byte, 12)
	binary.BigEndian.PutUint16(message[0:2], id)
	binary.BigEndian.PutUint16(message[2:4], 0x0100) // recursion desired
	binary.BigEndian.PutUint16(message[4:6], 1)      // QDCOUNT
	if payload > 0 {
		binary.BigEndian.PutUint16(message[10:12], 1) // ARCOUNT: one OPT record
	}
	for _, label := range splitLabels(name) {
		message = append(message, byte(len(label)))
		message = append(message, label...)
	}
	message = append(message, 0)    // root label
	message = append(message, 0, 1) // QTYPE A
	message = append(message, 0, 1) // QCLASS IN
	if payload > 0 {
		message = append(message, 0)     // OPT owner: root
		message = append(message, 0, 41) // TYPE OPT
		message = append(message, byte(payload>>8), byte(payload))
		message = append(message, 0, 0, 0, 0) // TTL
		message = append(message, 0, 0)       // RDLENGTH
	}
	return message
}

func splitLabels(name string) []string {
	var labels []string
	start := 0
	for i := 0; i < len(name); i++ {
		if name[i] == '.' {
			labels = append(labels, name[start:i])
			start = i + 1
		}
	}
	if start < len(name) {
		labels = append(labels, name[start:])
	}
	return labels
}

// buildResponse echoes the query and appends `answers` A records.
func buildResponse(query []byte, answers int) []byte {
	end, err := questionEnd(query)
	if err != nil {
		panic(err)
	}
	response := append([]byte(nil), query[:end]...)
	flags := binary.BigEndian.Uint16(response[2:4]) | dnsFlagQR
	binary.BigEndian.PutUint16(response[2:4], flags)
	binary.BigEndian.PutUint16(response[6:8], uint16(answers))
	// Drop the requestor's OPT record; a real resolver echoes its own.
	binary.BigEndian.PutUint16(response[10:12], 0)
	for i := 0; i < answers; i++ {
		record := make([]byte, 0, 16)
		record = append(record, 0xc0, 0x0c)         // pointer to the question name
		record = append(record, 0, 1)               // TYPE A
		record = append(record, 0, 1)               // CLASS IN
		record = append(record, 0, 0, 0, 60)        // TTL
		record = append(record, 0, 4)               // RDLENGTH
		record = append(record, 192, 0, 2, byte(i)) // 192.0.2.i
		response = append(response, record...)
	}
	return response
}

// startUpstream serves DNS-over-TCP on a Unix socket and applies handler.
func startUpstream(t *testing.T, handler func([]byte) []byte) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "upstream.sock")
	listener, err := net.Listen("unix", path)
	if err != nil {
		t.Fatalf("listen upstream: %v", err)
	}
	t.Cleanup(func() { listener.Close() })
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				return
			}
			go func() {
				defer conn.Close()
				for {
					query, err := readFrame(conn)
					if err != nil {
						return
					}
					if err := writeFrame(conn, handler(query)); err != nil {
						return
					}
				}
			}()
		}
	}()
	return path
}

// startRelay runs the relay on ephemeral ports and returns its client addresses.
func startRelay(t *testing.T, upstream string) (*net.UDPAddr, string) {
	t.Helper()
	udp, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.IPv4(127, 0, 0, 1)})
	if err != nil {
		t.Fatalf("listen udp: %v", err)
	}
	tcp, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen tcp: %v", err)
	}
	go serveDNS(udp, tcp, upstream)
	t.Cleanup(func() {
		udp.Close()
		tcp.Close()
	})
	return udp.LocalAddr().(*net.UDPAddr), tcp.Addr().String()
}

func askUDP(t *testing.T, address *net.UDPAddr, query []byte) []byte {
	t.Helper()
	conn, err := net.DialUDP("udp", nil, address)
	if err != nil {
		t.Fatalf("dial relay: %v", err)
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(5 * time.Second))
	if _, err := conn.Write(query); err != nil {
		t.Fatalf("write query: %v", err)
	}
	buffer := make([]byte, 4096)
	size, err := conn.Read(buffer)
	if err != nil {
		t.Fatalf("read answer: %v", err)
	}
	return buffer[:size]
}

func askTCP(t *testing.T, address string, queries ...[]byte) [][]byte {
	t.Helper()
	conn, err := net.Dial("tcp", address)
	if err != nil {
		t.Fatalf("dial relay: %v", err)
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(5 * time.Second))
	for _, query := range queries {
		if err := writeFrame(conn, query); err != nil {
			t.Fatalf("write query: %v", err)
		}
	}
	var answers [][]byte
	for range queries {
		answer, err := readFrame(conn)
		if err != nil {
			t.Fatalf("read answer: %v", err)
		}
		answers = append(answers, answer)
	}
	return answers
}

func rcode(answer []byte) int {
	return int(binary.BigEndian.Uint16(answer[2:4]) & 0x000f)
}

func TestUDPRelayReturnsUpstreamAnswer(t *testing.T) {
	upstream := startUpstream(t, func(query []byte) []byte {
		return buildResponse(query, 1)
	})
	udpAddr, _ := startRelay(t, upstream)

	answer := askUDP(t, udpAddr, buildQuery(0x1234, "example.test", 0))
	if binary.BigEndian.Uint16(answer[0:2]) != 0x1234 {
		t.Fatalf("answer lost the query ID: % x", answer[:2])
	}
	if got := binary.BigEndian.Uint16(answer[6:8]); got != 1 {
		t.Fatalf("expected one answer record, got %d", got)
	}
	if rcode(answer) != 0 {
		t.Fatalf("expected NOERROR, got rcode %d", rcode(answer))
	}
}

func TestUDPRelayFailsClosedOnMismatchedAnswer(t *testing.T) {
	upstream := startUpstream(t, func(query []byte) []byte {
		wrong := buildResponse(query, 1)
		binary.BigEndian.PutUint16(wrong[0:2], 0xbeef) // different query
		return wrong
	})
	udpAddr, _ := startRelay(t, upstream)

	answer := askUDP(t, udpAddr, buildQuery(0x2222, "example.test", 0))
	if got := rcode(answer); got != dnsRcodeSERVFAIL {
		t.Fatalf("expected SERVFAIL for a foreign answer, got rcode %d", got)
	}
}

func TestUDPRelayFailsClosedWhenUpstreamIsMissing(t *testing.T) {
	udpAddr, _ := startRelay(t, filepath.Join(t.TempDir(), "missing.sock"))

	answer := askUDP(t, udpAddr, buildQuery(0x3333, "example.test", 0))
	if got := rcode(answer); got != dnsRcodeSERVFAIL {
		t.Fatalf("expected SERVFAIL without an upstream, got rcode %d", got)
	}
}

func TestUDPRelayTruncatesAboveClassicLimit(t *testing.T) {
	upstream := startUpstream(t, func(query []byte) []byte {
		return buildResponse(query, 60) // far beyond 512 bytes
	})
	udpAddr, _ := startRelay(t, upstream)

	answer := askUDP(t, udpAddr, buildQuery(0x4444, "example.test", 0))
	flags := binary.BigEndian.Uint16(answer[2:4])
	if flags&dnsFlagTC == 0 {
		t.Fatal("expected the TC bit on an oversized answer")
	}
	if got := binary.BigEndian.Uint16(answer[6:8]); got != 0 {
		t.Fatalf("truncated answer must carry no records, got %d", got)
	}
	question, err := questionSection(answer)
	if err != nil {
		t.Fatalf("truncated answer lost its question: %v", err)
	}
	if want, _ := questionSection(buildQuery(0x4444, "example.test", 0)); string(question) != string(want) {
		t.Fatal("truncated answer did not echo the question")
	}
}

func TestUDPRelayHonoursEDNSPayloadSize(t *testing.T) {
	upstream := startUpstream(t, func(query []byte) []byte {
		return buildResponse(query, 40) // around 800 bytes: fits in 1232
	})
	udpAddr, _ := startRelay(t, upstream)

	answer := askUDP(t, udpAddr, buildQuery(0x5555, "example.test", 1232))
	if binary.BigEndian.Uint16(answer[2:4])&dnsFlagTC != 0 {
		t.Fatal("an EDNS0 client advertising 1232 must not receive a truncated answer")
	}
	if got := binary.BigEndian.Uint16(answer[6:8]); got != 40 {
		t.Fatalf("expected all 40 records, got %d", got)
	}
}

func TestTCPRelayServesPipelinedQueries(t *testing.T) {
	upstream := startUpstream(t, func(query []byte) []byte {
		return buildResponse(query, 1)
	})
	_, tcpAddr := startRelay(t, upstream)

	answers := askTCP(t, tcpAddr,
		buildQuery(0x6666, "first.test", 0),
		buildQuery(0x7777, "second.test", 0),
	)
	if binary.BigEndian.Uint16(answers[0][0:2]) != 0x6666 || binary.BigEndian.Uint16(answers[1][0:2]) != 0x7777 {
		t.Fatalf("answers arrived out of order: %x %x", answers[0][:2], answers[1][:2])
	}
}

func TestTCPRelayDoesNotTruncate(t *testing.T) {
	upstream := startUpstream(t, func(query []byte) []byte {
		return buildResponse(query, 40)
	})
	_, tcpAddr := startRelay(t, upstream)

	answers := askTCP(t, tcpAddr, buildQuery(0x8888, "example.test", 0))
	if binary.BigEndian.Uint16(answers[0][2:4])&dnsFlagTC != 0 {
		t.Fatal("TCP answers must never be truncated")
	}
	if got := binary.BigEndian.Uint16(answers[0][6:8]); got != 40 {
		t.Fatalf("expected all 40 records over TCP, got %d", got)
	}
}

func TestRelayDropsUndersizedQuery(t *testing.T) {
	udpAddr, _ := startRelay(t, startUpstream(t, func(query []byte) []byte {
		return buildResponse(query, 1)
	}))

	conn, err := net.DialUDP("udp", nil, udpAddr)
	if err != nil {
		t.Fatalf("dial relay: %v", err)
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(500 * time.Millisecond))
	if _, err := conn.Write([]byte{1, 2, 3}); err != nil {
		t.Fatalf("write query: %v", err)
	}
	buffer := make([]byte, 64)
	if _, err := conn.Read(buffer); err == nil {
		t.Fatal("a malformed datagram must be dropped, not answered")
	}
}
