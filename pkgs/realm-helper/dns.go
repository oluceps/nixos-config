package main

import (
	"encoding/binary"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"time"
)

const (
	dnsHeaderLen = 12
	// dnsUDPLimit is the classic UDP payload size; a larger answer is truncated
	// so the resolver retries over TCP, which this helper also serves.
	dnsUDPLimit = 512
	// dnsUDPLimitMax caps what an EDNS0 client may ask for.
	dnsUDPLimitMax = 4096
	// dnsMaxMessageLen is the largest DNS-over-TCP frame.
	dnsMaxMessageLen = 65535
	// dnsMaxInFlight bounds concurrent UDP queries; a full table drops new
	// datagrams and lets the client retry, instead of queueing without limit.
	dnsMaxInFlight   = 32
	dnsTimeout       = 5 * time.Second
	dnsIdleTimeout   = 30 * time.Second
	dnsFlagTC        = 0x0200
	dnsFlagQR        = 0x0080
	dnsRcodeSERVFAIL = 2
)

var errShortMessage = errors.New("short DNS message")

// dnsCommand serves DNS inside a workload namespace.
//
// The namespace has no route out, so the only way to reach a resolver is a Unix
// socket. UDP datagrams are relayed as DNS-over-TCP frames over that socket,
// and TCP queries are relayed unchanged. The upstream adapter on the host side
// can reach loopback only, so a client cannot select a resolver or turn DNS
// into a general network path.
func dnsCommand(args []string) error {
	flags := flag.NewFlagSet("dns", flag.ContinueOnError)
	upstream := flags.String("upstream", "", "Unix socket carrying DNS-over-TCP")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *upstream == "" {
		return errors.New("--upstream is required")
	}

	sockets, err := activatedSockets()
	if err != nil {
		return err
	}
	var udp *net.UDPConn
	var tcp net.Listener
	for _, socket := range sockets {
		switch socket.name {
		case "dns-udp":
			conn, err := net.FilePacketConn(socket.file)
			socket.file.Close()
			if err != nil {
				return fmt.Errorf("take dns-udp socket: %w", err)
			}
			packet, ok := conn.(*net.UDPConn)
			if !ok {
				conn.Close()
				return errors.New("dns-udp must be a datagram socket")
			}
			udp = packet
		case "dns-tcp":
			listener, err := net.FileListener(socket.file)
			socket.file.Close()
			if err != nil {
				return fmt.Errorf("take dns-tcp socket: %w", err)
			}
			tcp = listener
		}
	}
	if udp == nil || tcp == nil {
		return errors.New("both dns-udp and dns-tcp sockets are required")
	}
	return serveDNS(udp, tcp, *upstream)
}

// serveDNS runs the UDP relay and the TCP relay against one upstream socket.
func serveDNS(udp *net.UDPConn, tcp net.Listener, upstream string) error {
	inFlight := make(chan struct{}, dnsMaxInFlight)
	udpDone := make(chan struct{})

	go func() {
		defer close(udpDone)
		buffer := make([]byte, dnsMaxMessageLen)
		for {
			size, client, err := udp.ReadFromUDP(buffer)
			if err != nil {
				if errors.Is(err, net.ErrClosed) {
					return
				}
				continue
			}
			query := append([]byte(nil), buffer[:size]...)
			select {
			case inFlight <- struct{}{}:
				go func() {
					defer func() { <-inFlight }()
					if reply := relayUDP(query, upstream); reply != nil {
						udp.WriteToUDP(reply, client)
					}
				}()
			default:
				// Overloaded: the client's retry is cheaper than an unbounded queue.
			}
		}
	}()

	for {
		conn, err := tcp.Accept()
		if err != nil {
			udp.Close()
			<-udpDone
			return err
		}
		go relayDNSStream(conn, upstream)
	}
}

// relayUDP answers one datagram, or returns nil when the query is unusable.
func relayUDP(query []byte, upstream string) []byte {
	if len(query) < dnsHeaderLen {
		return nil
	}
	response, err := exchange(upstream, query)
	if err != nil || !responseMatches(query, response) {
		return servfail(query)
	}
	return truncateToClient(query, response)
}

// relayDNSStream serves length-prefixed queries on one TCP connection. TCP is
// not truncated: it is the path a resolver takes after a truncated UDP answer.
func relayDNSStream(conn net.Conn, upstream string) {
	defer conn.Close()
	for {
		// Resolvers keep connections open between queries, so only reading the
		// next query uses the longer idle limit; the exchange itself stays short.
		conn.SetDeadline(time.Now().Add(dnsIdleTimeout))
		query, err := readFrame(conn)
		if err != nil {
			return
		}
		response, err := exchange(upstream, query)
		if err != nil || !responseMatches(query, response) {
			response = servfail(query)
		}
		if err := writeFrame(conn, response); err != nil {
			return
		}
	}
}

// exchange sends one query over the upstream Unix socket and reads one answer.
func exchange(upstream string, query []byte) ([]byte, error) {
	conn, err := net.DialTimeout("unix", upstream, dnsTimeout)
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	if err := conn.SetDeadline(time.Now().Add(dnsTimeout)); err != nil {
		return nil, err
	}
	if err := writeFrame(conn, query); err != nil {
		return nil, err
	}
	return readFrame(conn)
}

func writeFrame(writer io.Writer, message []byte) error {
	if len(message) > dnsMaxMessageLen {
		return errors.New("DNS message larger than a TCP frame")
	}
	frame := make([]byte, 2+len(message))
	binary.BigEndian.PutUint16(frame, uint16(len(message)))
	copy(frame[2:], message)
	_, err := writer.Write(frame)
	return err
}

// readFrame reads one length-prefixed message, as used by DNS-over-TCP.
func readFrame(reader io.Reader) ([]byte, error) {
	var header [2]byte
	if _, err := io.ReadFull(reader, header[:]); err != nil {
		return nil, err
	}
	message := make([]byte, binary.BigEndian.Uint16(header[:]))
	if _, err := io.ReadFull(reader, message); err != nil {
		return nil, err
	}
	return message, nil
}

// responseMatches rejects answers produced for a different query. The upstream
// is a trusted local adapter, but comparing the ID and the echoed question
// keeps a stray or stale reply from being delivered as an answer.
func responseMatches(query, response []byte) bool {
	if len(query) < dnsHeaderLen || len(response) < dnsHeaderLen {
		return false
	}
	if query[0] != response[0] || query[1] != response[1] {
		return false
	}
	if binary.BigEndian.Uint16(response[2:4])&dnsFlagQR == 0 {
		return false
	}
	queryQuestion, err := questionSection(query)
	if err != nil {
		return false
	}
	responseQuestion, err := questionSection(response)
	if err != nil {
		return false
	}
	return string(queryQuestion) == string(responseQuestion)
}

// truncateToClient applies the UDP payload size the client advertised.
func truncateToClient(query, response []byte) []byte {
	limit := udpPayloadLimit(query)
	if len(response) <= limit {
		return response
	}
	end, err := questionEnd(response)
	if err != nil {
		return servfail(query)
	}

	reply := make([]byte, 0, end)
	reply = append(reply, response[:dnsHeaderLen]...)
	binary.BigEndian.PutUint16(reply[2:4], binary.BigEndian.Uint16(reply[2:4])|dnsFlagTC)
	// A truncated response carries the question only; the client retries over TCP.
	binary.BigEndian.PutUint16(reply[6:8], 0)
	binary.BigEndian.PutUint16(reply[8:10], 0)
	binary.BigEndian.PutUint16(reply[10:12], 0)
	return append(reply, response[dnsHeaderLen:end]...)
}

// servfail builds a SERVFAIL answer that echoes the client's question.
func servfail(query []byte) []byte {
	if len(query) < dnsHeaderLen {
		return nil
	}
	reply := make([]byte, dnsHeaderLen)
	copy(reply, query[:dnsHeaderLen])
	flags := binary.BigEndian.Uint16(reply[2:4])
	binary.BigEndian.PutUint16(reply[2:4], (flags|dnsFlagQR|dnsRcodeSERVFAIL)&^dnsFlagTC)
	binary.BigEndian.PutUint16(reply[4:6], 0)
	binary.BigEndian.PutUint16(reply[6:8], 0)
	binary.BigEndian.PutUint16(reply[8:10], 0)
	binary.BigEndian.PutUint16(reply[10:12], 0)
	if end, err := questionEnd(query); err == nil {
		reply = append(reply, query[dnsHeaderLen:end]...)
		binary.BigEndian.PutUint16(reply[4:6], binary.BigEndian.Uint16(query[4:6]))
	}
	return reply
}

// udpPayloadLimit returns the answer size a client accepts over UDP.
func udpPayloadLimit(query []byte) int {
	size, ok := advertisedPayload(query)
	if !ok {
		return dnsUDPLimit
	}
	return min(max(size, dnsUDPLimit), dnsUDPLimitMax)
}

// advertisedPayload reads the EDNS0 UDP payload size from the query's OPT RR.
func advertisedPayload(message []byte) (int, bool) {
	offset, err := questionEnd(message)
	if err != nil {
		return 0, false
	}
	records := int(binary.BigEndian.Uint16(message[6:8])) +
		int(binary.BigEndian.Uint16(message[8:10])) +
		int(binary.BigEndian.Uint16(message[10:12]))
	for i := 0; i < records; i++ {
		next, err := skipName(message, offset)
		if err != nil || next+10 > len(message) {
			return 0, false
		}
		// RR: name, type, class, TTL, RDLENGTH, RDATA. For OPT the class field
		// carries the requestor's maximum UDP payload size.
		if binary.BigEndian.Uint16(message[next:]) == 41 {
			return int(binary.BigEndian.Uint16(message[next+2:])), true
		}
		offset = next + 10 + int(binary.BigEndian.Uint16(message[next+8:]))
		if offset > len(message) {
			return 0, false
		}
	}
	return 0, false
}

// questionSection returns the question section bytes, which a response echoes.
func questionSection(message []byte) ([]byte, error) {
	end, err := questionEnd(message)
	if err != nil {
		return nil, err
	}
	return message[dnsHeaderLen:end], nil
}

// questionEnd returns the offset just past the question section.
func questionEnd(message []byte) (int, error) {
	if len(message) < dnsHeaderLen {
		return 0, errShortMessage
	}
	offset := dnsHeaderLen
	for range int(binary.BigEndian.Uint16(message[4:6])) {
		next, err := skipName(message, offset)
		if err != nil {
			return 0, err
		}
		if next+4 > len(message) {
			return 0, errShortMessage
		}
		offset = next + 4
	}
	return offset, nil
}

// skipName returns the offset just past a possibly compressed name.
func skipName(message []byte, offset int) (int, error) {
	for {
		if offset >= len(message) {
			return 0, errShortMessage
		}
		length := int(message[offset])
		switch {
		case length == 0:
			return offset + 1, nil
		case length&0xc0 == 0xc0:
			if offset+1 >= len(message) {
				return 0, errShortMessage
			}
			return offset + 2, nil
		case length&0xc0 != 0:
			return 0, errors.New("unsupported label type in DNS name")
		default:
			offset += 1 + length
		}
	}
}
