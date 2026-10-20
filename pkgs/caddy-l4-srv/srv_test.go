package caddysrv

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"errors"
	"io"
	"math/big"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/mholt/caddy-l4/layer4"
	"github.com/miekg/dns"
	"go.uber.org/zap"
)

type fakeResolver struct {
	mu      sync.Mutex
	records []*net.SRV
	ips     map[string][]net.IPAddr
	err     error
	calls   int
}

func (r *fakeResolver) LookupSRV(context.Context, string, string, string) (string, []*net.SRV, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.calls++
	return "", r.records, r.err
}
func (r *fakeResolver) LookupIPAddr(_ context.Context, host string) ([]net.IPAddr, error) {
	return append([]net.IPAddr(nil), r.ips[host]...), nil
}

func provision(t *testing.T, h *Handler) {
	t.Helper()
	ctx, cancel := caddy.NewContext(caddy.Context{Context: context.Background()})
	t.Cleanup(cancel)
	if err := h.Provision(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestCacheConcurrentRefreshAndNoStaleOnFailure(t *testing.T) {
	r := &fakeResolver{records: []*net.SRV{{Target: "one.", Port: 443}}}
	h := &Handler{Refresh: caddy.Duration(time.Hour), DialTimeout: caddy.Duration(time.Second), lookup: r}
	var wg sync.WaitGroup
	for range 32 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if _, err := h.srvRecords(context.Background()); err != nil {
				t.Error(err)
			}
		}()
	}
	wg.Wait()
	if r.calls != 1 {
		t.Fatalf("concurrent requests issued %d refreshes", r.calls)
	}
	h.expires = time.Time{}
	r.records = []*net.SRV{{Target: "two.", Port: 8443}}
	got, err := h.srvRecords(context.Background())
	if err != nil || len(got) != 1 || got[0].Target != "two." {
		t.Fatalf("new endpoint not observed: %v, %v", got, err)
	}
	h.expires = time.Time{}
	r.err = errors.New("discovery unavailable")
	got, err = h.srvRecords(context.Background())
	if err == nil || len(got) != 0 {
		t.Fatalf("served expired records on failure: %v, %v", got, err)
	}
	// Negative results are briefly cached instead of hammering unavailable DNS.
	_, _ = h.srvRecords(context.Background())
	if r.calls != 3 {
		t.Fatalf("unexpected refresh count: %d", r.calls)
	}
}

func TestPriorityAndWeightOrdering(t *testing.T) {
	records := []*net.SRV{
		{Target: "backup", Priority: 10},
		{Target: "zero", Priority: 0, Weight: 0},
		{Target: "primary", Priority: 0, Weight: 10},
	}
	for range 100 {
		got := ordered(records)
		if len(got) != 3 || got[0].Target != "primary" || got[2].Target != "backup" {
			t.Fatalf("incorrect priority/weight ordering: %v", got)
		}
	}
	if records[0].Target != "backup" {
		t.Fatal("modified cached ordering")
	}
}

func TestUnavailableSRV(t *testing.T) {
	for _, record := range []*net.SRV{{Target: ".", Port: 443}, {Target: "host.", Port: 0}} {
		h := &Handler{Refresh: caddy.Duration(time.Second), DialTimeout: caddy.Duration(time.Second), lookup: &fakeResolver{records: []*net.SRV{record}}}
		if _, err := h.srvRecords(context.Background()); err == nil {
			t.Fatal("accepted unavailable SRV endpoint")
		}
	}
}

func TestDialFallback(t *testing.T) {
	live, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer live.Close()
	closed, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	deadPort := uint16(closed.Addr().(*net.TCPAddr).Port)
	_ = closed.Close()
	h := &Handler{Refresh: caddy.Duration(time.Second), DialTimeout: caddy.Duration(time.Second), lookup: &fakeResolver{
		records: []*net.SRV{
			{Target: "dead.", Port: deadPort, Priority: 0},
			{Target: "live.", Port: uint16(live.Addr().(*net.TCPAddr).Port), Priority: 1},
		},
		ips: map[string][]net.IPAddr{
			"dead.": {{IP: net.ParseIP("127.0.0.1")}},
			"live.": {{IP: net.ParseIP("127.0.0.1")}},
		},
	}}
	conn, err := h.dial(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	if conn.RemoteAddr().String() != live.Addr().String() {
		t.Fatalf("did not reach fallback: %v", conn.RemoteAddr())
	}
}

func TestRelayHalfCloseAndPrefetchedBytes(t *testing.T) {
	upstream, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer upstream.Close()
	serverDone := make(chan error, 1)
	go func() {
		conn, err := upstream.Accept()
		if err != nil {
			serverDone <- err
			return
		}
		defer conn.Close()
		_ = conn.SetDeadline(time.Now().Add(5 * time.Second))
		data, err := io.ReadAll(conn)
		if err == nil {
			_, err = conn.Write(append([]byte("reply:"), data...))
		}
		serverDone <- err
	}()
	h := &Handler{Name: "test.service.consul", ctx: context.Background(), Refresh: caddy.Duration(time.Second), DialTimeout: caddy.Duration(time.Second), lookup: &fakeResolver{
		records: []*net.SRV{{Target: "backend.", Port: uint16(upstream.Addr().(*net.TCPAddr).Port)}},
		ips:     map[string][]net.IPAddr{"backend.": {{IP: net.ParseIP("127.0.0.1")}}},
	}}
	dir, err := os.MkdirTemp("", "srv-")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.RemoveAll(dir) })
	socket := filepath.Join(dir, "relay.sock")
	listener, err := net.Listen("unix", socket)
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	handlerDone := make(chan error, 1)
	go func() {
		conn, err := listener.Accept()
		if err != nil {
			handlerDone <- err
			return
		}
		defer conn.Close()
		prefix := make([]byte, 3)
		if _, err := io.ReadFull(conn, prefix); err != nil {
			handlerDone <- err
			return
		}
		handlerDone <- h.Handle(layer4.WrapConnection(conn, prefix, zap.NewNop()), nil)
	}()
	client, err := net.DialUnix("unix", nil, &net.UnixAddr{Name: socket, Net: "unix"})
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	_ = client.SetDeadline(time.Now().Add(5 * time.Second))
	_, _ = client.Write([]byte("prefetched-and-live"))
	_ = client.CloseWrite()
	got, err := io.ReadAll(client)
	if err != nil || string(got) != "reply:prefetched-and-live" {
		t.Fatalf("half-close lost response/buffer: %q, %v", got, err)
	}
	if err := <-handlerDone; err != nil {
		t.Fatal(err)
	}
	if err := <-serverDone; err != nil {
		t.Fatal(err)
	}
}

// dnsFixture supplies both SRV and target IP records on a nonstandard port.
func dnsFixture(t *testing.T, backend net.Addr, truncateUDP bool) string {
	t.Helper()
	port := uint16(backend.(*net.TCPAddr).Port)
	ip := backend.(*net.TCPAddr).IP
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	packet, err := net.ListenPacket("udp", listener.Addr().String())
	if err != nil {
		_ = listener.Close()
		t.Fatal(err)
	}
	handler := dns.HandlerFunc(func(w dns.ResponseWriter, req *dns.Msg) {
		msg := new(dns.Msg)
		msg.SetReply(req)
		msg.Authoritative = true
		if truncateUDP && w.LocalAddr().Network() == "udp" {
			msg.Truncated = true
			_ = w.WriteMsg(msg)
			return
		}
		for _, q := range req.Question {
			switch {
			case q.Name == "test.service.consul." && q.Qtype == dns.TypeSRV:
				msg.Answer = append(msg.Answer, &dns.SRV{Hdr: dns.RR_Header{Name: q.Name, Rrtype: dns.TypeSRV, Class: dns.ClassINET, Ttl: 0}, Port: port, Target: "backend.service.consul."})
			case q.Name == "backend.service.consul." && q.Qtype == dns.TypeA && ip.To4() != nil:
				msg.Answer = append(msg.Answer, &dns.A{Hdr: dns.RR_Header{Name: q.Name, Rrtype: dns.TypeA, Class: dns.ClassINET, Ttl: 0}, A: ip})
			case q.Name == "backend.service.consul." && q.Qtype == dns.TypeAAAA && ip.To4() == nil:
				msg.Answer = append(msg.Answer, &dns.AAAA{Hdr: dns.RR_Header{Name: q.Name, Rrtype: dns.TypeAAAA, Class: dns.ClassINET, Ttl: 0}, AAAA: ip})
			}
		}
		_ = w.WriteMsg(msg)
	})
	for _, server := range []*dns.Server{{PacketConn: packet, Handler: handler}, {Listener: listener, Handler: handler}} {
		go func() { _ = server.ActivateAndServe() }()
		t.Cleanup(func() { _ = server.Shutdown() })
	}
	return packet.LocalAddr().String()
}

func TestIPv6DiscoveryWithTruncatedUDP(t *testing.T) {
	backend, err := net.Listen("tcp6", "[::1]:0")
	if err != nil {
		t.Skipf("IPv6 loopback unavailable: %v", err)
	}
	defer backend.Close()
	h := &Handler{Name: "test.service.consul", Resolver: dnsFixture(t, backend.Addr(), true)}
	provision(t, h)
	conn, err := h.dial(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	if conn.RemoteAddr().String() != backend.Addr().String() {
		t.Fatalf("did not discover IPv6 endpoint: %v", conn.RemoteAddr())
	}
}

func testCertificates(t *testing.T) (tls.Certificate, tls.Certificate, *x509.CertPool) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	ca := &x509.Certificate{SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "fixture CA"}, NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(time.Hour), IsCA: true, BasicConstraintsValid: true, KeyUsage: x509.KeyUsageCertSign}
	der, err := x509.CreateCertificate(rand.Reader, ca, ca, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	pool := x509.NewCertPool()
	parsed, err := x509.ParseCertificate(der)
	if err != nil {
		t.Fatal(err)
	}
	pool.AddCert(parsed)
	issue := func(serial int64, id string) tls.Certificate {
		leafKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			t.Fatal(err)
		}
		uri, _ := url.Parse(id)
		leaf := &x509.Certificate{SerialNumber: big.NewInt(serial), NotBefore: ca.NotBefore, NotAfter: ca.NotAfter, IPAddresses: []net.IP{net.ParseIP("127.0.0.1")}, URIs: []*url.URL{uri}, KeyUsage: x509.KeyUsageDigitalSignature, ExtKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth, x509.ExtKeyUsageClientAuth}}
		cert, err := x509.CreateCertificate(rand.Reader, leaf, ca, &leafKey.PublicKey, key)
		if err != nil {
			t.Fatal(err)
		}
		return tls.Certificate{Certificate: [][]byte{cert}, PrivateKey: leafKey}
	}
	return issue(2, "spiffe://nyaw.xyz/service/server"), issue(3, "spiffe://nyaw.xyz/service/client"), pool
}

func TestCaddyUnixListenerSRVAndMutualTLSPassthrough(t *testing.T) {
	serverCert, clientCert, roots := testCertificates(t)
	backend, err := tls.Listen("tcp", "127.0.0.1:0", &tls.Config{Certificates: []tls.Certificate{serverCert}, ClientAuth: tls.RequireAndVerifyClientCert, ClientCAs: roots, MinVersion: tls.VersionTLS12})
	if err != nil {
		t.Fatal(err)
	}
	defer backend.Close()
	serverDone := make(chan error, 1)
	go func() {
		conn, err := backend.Accept()
		if err != nil {
			serverDone <- err
			return
		}
		defer conn.Close()
		_ = conn.SetDeadline(time.Now().Add(5 * time.Second))
		tlsConn := conn.(*tls.Conn)
		if err = tlsConn.Handshake(); err == nil {
			state := tlsConn.ConnectionState()
			if state.ServerName != "" {
				err = errors.New("expected connection without SNI")
			}
			if got := state.PeerCertificates[0].URIs[0].String(); got != "spiffe://nyaw.xyz/service/client" {
				err = errors.New("client identity changed")
			}
		}
		if err == nil {
			var data [4]byte
			_, err = io.ReadFull(conn, data[:])
			if err == nil {
				_, err = conn.Write(data[:])
			}
		}
		serverDone <- err
	}()
	dir, err := os.MkdirTemp("", "srv-caddy-")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.RemoveAll(dir) })
	socket := filepath.Join(dir, "mesh.sock")
	config := map[string]any{
		"admin": map[string]any{"disabled": true},
		"apps": map[string]any{"layer4": map[string]any{"servers": map[string]any{"discovery": map[string]any{
			"listen": []string{"unix/" + socket},
			"routes": []any{map[string]any{"handle": []any{map[string]any{"handler": "srv_proxy", "name": "test.service.consul", "resolver": dnsFixture(t, backend.Addr(), false), "dial_timeout": "2s"}}}},
		}}}},
	}
	raw, err := json.Marshal(config)
	if err != nil {
		t.Fatal(err)
	}
	if err = caddy.Load(raw, true); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = caddy.Stop() })
	plain, err := net.DialTimeout("unix", socket, 5*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer plain.Close()
	// Go omits SNI for IP literals, matching ghostunnel's Unix-target behavior.
	client := tls.Client(plain, &tls.Config{Certificates: []tls.Certificate{clientCert}, RootCAs: roots, ServerName: "127.0.0.1", MinVersion: tls.VersionTLS12})
	_ = client.SetDeadline(time.Now().Add(5 * time.Second))
	if err = client.Handshake(); err != nil {
		t.Fatal(err)
	}
	if got := client.ConnectionState().PeerCertificates[0].URIs[0].String(); got != "spiffe://nyaw.xyz/service/server" {
		t.Fatalf("server identity changed: %s", got)
	}
	_, _ = client.Write([]byte("ping"))
	var reply [4]byte
	if _, err = io.ReadFull(client, reply[:]); err != nil || string(reply[:]) != "ping" {
		t.Fatalf("TLS payload lost: %q %v", reply, err)
	}
	_ = client.Close()
	if err := <-serverDone; err != nil {
		t.Fatal(err)
	}
}

func TestConfiguration(t *testing.T) {
	h := new(Handler)
	if err := h.UnmarshalCaddyfile(caddyfile.NewTestDispenser("srv_proxy test.service.consul {\n resolver 127.0.0.1:8600\n refresh 2s\n dial_timeout 1s\n}")); err != nil {
		t.Fatal(err)
	}
	provision(t, h)
	if h.Name != "test.service.consul." || h.Refresh != caddy.Duration(2*time.Second) {
		t.Fatalf("bad configuration: %+v", h)
	}
	for _, h := range []*Handler{
		{Name: "spiffe://nyaw.xyz/service/loki"},
		{Name: "{l4.tls.server_name}"},
		{Name: "test.service.consul", Resolver: "untrusted.test:53"},
		{Name: "test.service.consul", Resolver: "127.0.0.1:0"},
		{Name: "test.service.consul", Refresh: -1},
	} {
		ctx, cancel := caddy.NewContext(caddy.Context{Context: context.Background()})
		if err := h.Provision(ctx); err == nil {
			t.Errorf("accepted invalid configuration: %+v", h)
		}
		cancel()
	}
	if err := new(Handler).UnmarshalCaddyfile(caddyfile.NewTestDispenser("srv_proxy test.service.consul {\n refresh -1s\n}")); err == nil {
		t.Fatal("accepted negative refresh")
	}
}

func TestContextCancellationClosesBothStreams(t *testing.T) {
	backend, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer backend.Close()
	accepted := make(chan net.Conn, 1)
	go func() {
		conn, err := backend.Accept()
		if err == nil {
			accepted <- conn
		}
	}()
	h := &Handler{Name: "test.service.consul", Resolver: dnsFixture(t, backend.Addr(), false)}
	provision(t, h)
	ctx, cancel := context.WithCancel(h.ctx)
	h.ctx = ctx
	defer cancel()
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	// net.Pipe reports the synthetic network "pipe"; use a TCP-like address.
	down := &addressConn{Conn: server}
	done := make(chan error, 1)
	go func() { done <- h.Handle(layer4.WrapConnection(down, nil, zap.NewNop()), nil) }()
	select {
	case conn := <-accepted:
		defer conn.Close()
	case <-time.After(3 * time.Second):
		t.Fatal("upstream not connected")
	}
	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("normal cancellation reported as a stream error: %v", err)
		}
	case <-time.After(time.Second):
		t.Fatal("cancelled handler leaked a relay goroutine")
	}
}

type addressConn struct{ net.Conn }

func (*addressConn) LocalAddr() net.Addr { return &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1), Port: 1234} }

func TestUnreachableEndpointsInvalidateCache(t *testing.T) {
	h := &Handler{Name: "test.service.consul", Refresh: caddy.Duration(time.Hour), DialTimeout: caddy.Duration(time.Second), lookup: &fakeResolver{records: []*net.SRV{{Target: "missing.", Port: 443}}}}
	if _, err := h.dial(context.Background()); err == nil || !strings.Contains(err.Error(), "no reachable endpoint") {
		t.Fatalf("unexpected error: %v", err)
	}
	if !h.expires.IsZero() {
		t.Fatal("failed endpoint set remained cached")
	}
}
