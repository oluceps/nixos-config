// Package caddysrv provides DNS SRV discovery for transparent Caddy L4 streams.
package caddysrv

import (
	"context"
	"errors"
	"fmt"
	"io"
	"math/rand/v2"
	"net"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/mholt/caddy-l4/layer4"
	"go.uber.org/zap"
)

func init() { caddy.RegisterModule(&Handler{}) }

// Handler is a terminal TCP/Unix-stream handler. It does not terminate TLS.
// Name is a complete SRV query name, not a dial address or a SPIFFE identity.
type Handler struct {
	Name        string         `json:"name"`
	Resolver    string         `json:"resolver,omitempty"`
	Refresh     caddy.Duration `json:"refresh,omitempty"`
	DialTimeout caddy.Duration `json:"dial_timeout,omitempty"`

	ctx      context.Context
	lookup   resolver
	mu       sync.Mutex
	records  []*net.SRV
	expires  time.Time
	queryErr error
}

type resolver interface {
	LookupSRV(context.Context, string, string, string) (string, []*net.SRV, error)
	LookupIPAddr(context.Context, string) ([]net.IPAddr, error)
}

func (*Handler) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "layer4.handlers.srv_proxy",
		New: func() caddy.Module { return new(Handler) },
	}
}

func (h *Handler) Provision(ctx caddy.Context) error {
	h.ctx = ctx
	if h.Name == "" || strings.ContainsAny(h.Name, " /:\t\r\n{}") || len(h.Name) > 253 {
		return fmt.Errorf("name must be a literal, fully qualified SRV query name")
	}
	if h.Resolver == "" {
		h.Resolver = "127.0.0.1:8600"
	}
	host, port, err := net.SplitHostPort(h.Resolver)
	if err != nil || net.ParseIP(host) == nil {
		return fmt.Errorf("resolver must be a literal IP:port")
	}
	n, err := strconv.Atoi(port)
	if err != nil || n < 1 || n > 65535 {
		return fmt.Errorf("resolver port must be in 1..65535")
	}
	if h.Refresh == 0 {
		h.Refresh = caddy.Duration(5 * time.Second)
	}
	if h.DialTimeout == 0 {
		h.DialTimeout = caddy.Duration(5 * time.Second)
	}
	if h.Refresh < 0 || h.DialTimeout < 0 {
		return fmt.Errorf("refresh and dial_timeout must be positive")
	}
	h.Name = strings.TrimSuffix(h.Name, ".") + "."
	h.lookup = &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, _ string) (net.Conn, error) {
			return (&net.Dialer{Timeout: time.Duration(h.DialTimeout)}).DialContext(ctx, network, h.Resolver)
		},
	}
	return nil
}

// srvRecords coalesces refreshes. Expired answers are never served on DNS errors.
// Refresh is an explicit cache lifetime; Go's resolver does not expose DNS TTLs.
func (h *Handler) srvRecords(ctx context.Context) ([]*net.SRV, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if time.Now().Before(h.expires) {
		return ordered(h.records), h.queryErr
	}
	queryCtx, cancel := context.WithTimeout(ctx, time.Duration(h.DialTimeout))
	defer cancel()
	_, records, err := h.lookup.LookupSRV(queryCtx, "", "", h.Name)
	err = h.dnsError(err)
	h.records = nil
	for _, record := range records {
		if record.Target != "." && record.Target != "" && record.Port != 0 {
			h.records = append(h.records, record)
		}
	}
	if err == nil && len(h.records) == 0 {
		err = errors.New("SRV answer has no usable endpoints")
	}
	h.queryErr = err
	lifetime := time.Duration(h.Refresh)
	if err != nil {
		h.records = nil
		lifetime = min(lifetime, time.Second)
	}
	h.expires = time.Now().Add(lifetime)
	return ordered(h.records), err
}

// net.Resolver reports the system DNS address even when Dial overrides it.
func (h *Handler) dnsError(err error) error {
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		reported := *dnsErr
		reported.Server = h.Resolver
		return &reported
	}
	return err
}

// ordered chooses a fresh priority/weight ordering for every connection.
func ordered(records []*net.SRV) []*net.SRV {
	remaining := append([]*net.SRV(nil), records...)
	sort.SliceStable(remaining, func(i, j int) bool { return remaining[i].Priority < remaining[j].Priority })
	result := make([]*net.SRV, 0, len(remaining))
	for len(remaining) > 0 {
		count, total := 0, uint64(0)
		for count < len(remaining) && remaining[count].Priority == remaining[0].Priority {
			total += uint64(remaining[count].Weight)
			count++
		}
		index := 0
		if total == 0 {
			index = rand.IntN(count)
		} else {
			pick := rand.Uint64N(total)
			for pick >= uint64(remaining[index].Weight) {
				pick -= uint64(remaining[index].Weight)
				index++
			}
		}
		result = append(result, remaining[index])
		remaining = append(remaining[:index], remaining[index+1:]...)
	}
	return result
}

func (h *Handler) dial(ctx context.Context) (net.Conn, error) {
	records, err := h.srvRecords(ctx)
	if err != nil {
		return nil, fmt.Errorf("SRV lookup %s: %w", h.Name, err)
	}
	var lastErr error
	for _, record := range records {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		queryCtx, cancel := context.WithTimeout(ctx, time.Duration(h.DialTimeout))
		addresses, lookupErr := h.lookup.LookupIPAddr(queryCtx, record.Target)
		cancel()
		if lookupErr != nil {
			lastErr = h.dnsError(lookupErr)
			continue
		}
		// The mesh is IPv6; retain IPv4 fallback for other Consul deployments.
		sort.SliceStable(addresses, func(i, j int) bool {
			return addresses[i].IP.To4() == nil && addresses[j].IP.To4() != nil
		})
		for _, address := range addresses {
			target := net.JoinHostPort(address.String(), strconv.Itoa(int(record.Port)))
			conn, dialErr := (&net.Dialer{Timeout: time.Duration(h.DialTimeout)}).DialContext(ctx, "tcp", target)
			if dialErr == nil {
				return conn, nil
			}
			lastErr = dialErr
		}
	}
	// The next connection should refresh discovery immediately after complete failure.
	h.mu.Lock()
	h.expires = time.Time{}
	h.mu.Unlock()
	if lastErr == nil {
		lastErr = errors.New("targets have no addresses")
	}
	return nil, fmt.Errorf("no reachable endpoint for %s: %w", h.Name, lastErr)
}

func (h *Handler) Handle(down *layer4.Connection, _ layer4.Handler) error {
	if network := down.LocalAddr().Network(); network != "unix" && !strings.HasPrefix(network, "tcp") {
		return fmt.Errorf("srv_proxy supports TCP and Unix streams only")
	}
	ctx, cancel := context.WithCancel(h.ctx)
	stopDown := context.AfterFunc(down.Context, cancel)
	defer stopDown()
	defer cancel()
	up, err := h.dial(ctx)
	if err != nil {
		return err
	}
	defer up.Close()
	stop := context.AfterFunc(ctx, func() {
		_ = up.Close()
		_ = down.Close()
	})
	defer stop()
	return relay(down, up)
}

func relay(down *layer4.Connection, up net.Conn) error {
	// Read from down, not down.Conn: matchers may have prefetched TLS bytes.
	done := make(chan error, 1)
	copyStream := func(dst io.Writer, src io.Reader, half net.Conn) error {
		_, err := io.Copy(dst, src)
		if err == nil {
			if closer, ok := half.(interface{ CloseWrite() error }); ok {
				err = closer.CloseWrite()
			}
		}
		if err != nil {
			_ = up.Close()
			_ = down.Close()
		}
		// Peer disconnects and a concurrent close during shutdown are normal.
		// Keep genuine I/O failures visible to Caddy's error logger.
		if errors.Is(err, net.ErrClosed) || errors.Is(err, io.ErrClosedPipe) || errors.Is(err, syscall.EPIPE) ||
			errors.Is(err, syscall.ECONNRESET) || errors.Is(err, syscall.ENOTCONN) {
			down.Logger.Debug("stream closed by peer or shutdown", zap.Error(err))
			return nil
		}
		return err
	}
	go func() { done <- copyStream(up, down, up) }()
	err := copyStream(down, up, down.Conn)
	return errors.Join(err, <-done)
}

// UnmarshalCaddyfile accepts: srv_proxy <SRV-name> { resolver; refresh; dial_timeout }.
func (h *Handler) UnmarshalCaddyfile(d *caddyfile.Dispenser) error {
	for d.Next() {
		if !d.AllArgs(&h.Name) {
			return d.ArgErr()
		}
		for d.NextBlock(0) {
			option := d.Val()
			var value string
			if !d.AllArgs(&value) {
				return d.ArgErr()
			}
			switch option {
			case "resolver":
				h.Resolver = value
			case "refresh", "dial_timeout":
				duration, err := caddy.ParseDuration(value)
				if err != nil || duration <= 0 {
					return d.Errf("%s must be a positive duration", option)
				}
				if option == "refresh" {
					h.Refresh = caddy.Duration(duration)
				} else {
					h.DialTimeout = caddy.Duration(duration)
				}
			default:
				return d.Errf("unknown srv_proxy option %s", option)
			}
		}
	}
	return nil
}

var (
	_ caddy.Provisioner     = (*Handler)(nil)
	_ caddyfile.Unmarshaler = (*Handler)(nil)
	_ layer4.NextHandler    = (*Handler)(nil)
)
