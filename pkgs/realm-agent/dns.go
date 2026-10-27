package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/netip"
	"strings"
	"time"

	"github.com/miekg/dns"
)

type resolver struct {
	w      workload
	client *http.Client
	hosts  map[string][]netip.Addr
	limit  chan struct{}
}

func newResolver(w workload) *resolver {
	r := &resolver{w: w, hosts: map[string][]netip.Addr{}, limit: make(chan struct{}, 64)}
	for name, addresses := range w.DNSHosts {
		for _, s := range addresses {
			r.hosts[dns.CanonicalName(name)] = append(r.hosts[dns.CanonicalName(name)], netip.MustParseAddr(s))
		}
	}
	tr := &http.Transport{Proxy: nil, MaxIdleConns: 8, MaxIdleConnsPerHost: 8, IdleConnTimeout: 60 * time.Second, TLSHandshakeTimeout: 5 * time.Second, ResponseHeaderTimeout: 5 * time.Second, MaxResponseHeaderBytes: 8192,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return dialTunnel(ctx, w.InternetSocket, addr)
		},
	}
	r.client = &http.Client{Transport: tr, Timeout: 8 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	return r
}

func (r *resolver) answer(q *dns.Msg) *dns.Msg {
	a := new(dns.Msg)
	a.SetReply(q)
	a.RecursionAvailable = r.w.InternetSocket != ""
	if q.Opcode != dns.OpcodeQuery || len(q.Question) != 1 || q.Question[0].Qclass != dns.ClassINET {
		a.Rcode = dns.RcodeFormatError
		return a
	}
	question := q.Question[0]
	if addresses, ok := r.hosts[dns.CanonicalName(question.Name)]; ok {
		a.Authoritative = true
		for _, ip := range addresses {
			h := dns.RR_Header{Name: question.Name, Class: dns.ClassINET, Ttl: 60}
			if question.Qtype == dns.TypeA && ip.Is4() {
				h.Rrtype = dns.TypeA
				a.Answer = append(a.Answer, &dns.A{Hdr: h, A: net.IP(ip.AsSlice())})
			}
			if question.Qtype == dns.TypeAAAA && ip.Is6() {
				h.Rrtype = dns.TypeAAAA
				a.Answer = append(a.Answer, &dns.AAAA{Hdr: h, AAAA: net.IP(ip.AsSlice())})
			}
		}
		return a
	}
	if r.w.InternetSocket == "" {
		a.Rcode = dns.RcodeRefused
		return a
	}
	select {
	case r.limit <- struct{}{}:
		defer func() { <-r.limit }()
	default:
		a.Rcode = dns.RcodeServerFailure
		return a
	}
	raw, e := q.Pack()
	if e != nil {
		a.Rcode = dns.RcodeFormatError
		return a
	}
	req, e := http.NewRequest(http.MethodPost, r.w.DNSUpstream, bytes.NewReader(raw))
	if e != nil {
		a.Rcode = dns.RcodeServerFailure
		return a
	}
	req.Header.Set("Content-Type", "application/dns-message")
	req.Header.Set("Accept", "application/dns-message")
	resp, e := r.client.Do(req)
	if e != nil {
		a.Rcode = dns.RcodeServerFailure
		return a
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 || !strings.HasPrefix(resp.Header.Get("Content-Type"), "application/dns-message") {
		a.Rcode = dns.RcodeServerFailure
		return a
	}
	body, e := io.ReadAll(io.LimitReader(resp.Body, 65536))
	if e != nil || len(body) > 65535 {
		a.Rcode = dns.RcodeServerFailure
		return a
	}
	upstream := new(dns.Msg)
	if e = upstream.Unpack(body); e != nil || !upstream.Response || upstream.Id != q.Id || len(upstream.Question) != 1 || upstream.Question[0] != question {
		a.Rcode = dns.RcodeServerFailure
		return a
	}
	return upstream
}

func (r *resolver) ServeDNS(w dns.ResponseWriter, q *dns.Msg) {
	a := r.answer(q)
	if _, ok := w.RemoteAddr().(*net.UDPAddr); ok {
		size := 512
		if opt := q.IsEdns0(); opt != nil {
			size = int(opt.UDPSize())
			if size < 512 {
				size = 512
			}
			if size > 1232 {
				size = 1232
			}
		}
		a.Truncate(size)
	}
	_ = w.WriteMsg(a)
}

func (r *resolver) tcp(c net.Conn) {
	defer c.Close()
	dc := &dns.Conn{Conn: c}
	for i := 0; i < 128; i++ {
		c.SetDeadline(time.Now().Add(15 * time.Second))
		q, e := dc.ReadMsg()
		if e != nil {
			return
		}
		if e = dc.WriteMsg(r.answer(q)); e != nil {
			return
		}
	}
}

func startDNS(r *resolver, base uint16) ([]*dns.Server, error) {
	var servers []*dns.Server
	cleanup := func() {
		for _, s := range servers {
			_ = s.Shutdown()
		}
	}
	for i := 0; i < 8; i++ {
		for _, network := range []string{"udp4", "udp6"} {
			host := "127.0.0.1"
			if network == "udp6" {
				host = "::1"
			}
			pc, e := net.ListenPacket(network, net.JoinHostPort(host, fmt.Sprint(int(base)+i)))
			if e != nil {
				cleanup()
				return nil, e
			}
			s := &dns.Server{PacketConn: pc, Handler: r, UDPSize: 1232, ReadTimeout: 10 * time.Second, WriteTimeout: 10 * time.Second}
			servers = append(servers, s)
			go func() { _ = s.ActivateAndServe() }()
		}
	}
	return servers, nil
}
