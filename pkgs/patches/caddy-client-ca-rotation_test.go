// This file is copied into Caddy's caddytls package by caddy-realm.nix.
package caddytls

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"errors"
	"math/big"
	"net"
	"sync/atomic"
	"testing"
	"time"

	"github.com/caddyserver/caddy/v2"
)

// Publish immutable pools, just like the SPIFFE trust-bundle provider.
type realmRotatingCA struct{ pool atomic.Pointer[x509.CertPool] }

func (ca *realmRotatingCA) CertPool() *x509.CertPool { return ca.pool.Load() }

func TestRealmClientCARotation(t *testing.T) {
	makeIdentity := func(name string) (*x509.Certificate, tls.Certificate) {
		t.Helper()
		key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			t.Fatal(err)
		}
		now := time.Now()
		root := &x509.Certificate{
			SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: name},
			NotBefore: now.Add(-time.Hour), NotAfter: now.Add(time.Hour),
			IsCA: true, BasicConstraintsValid: true,
			KeyUsage: x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
		}
		der, err := x509.CreateCertificate(rand.Reader, root, root, &key.PublicKey, key)
		if err != nil {
			t.Fatal(err)
		}
		root, err = x509.ParseCertificate(der)
		if err != nil {
			t.Fatal(err)
		}
		leafKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			t.Fatal(err)
		}
		leaf := &x509.Certificate{
			SerialNumber: big.NewInt(2), Subject: pkix.Name{CommonName: name + " client"},
			DNSNames:  []string{"localhost"},
			NotBefore: now.Add(-time.Hour), NotAfter: now.Add(time.Hour),
			KeyUsage:    x509.KeyUsageDigitalSignature,
			ExtKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageClientAuth, x509.ExtKeyUsageServerAuth},
		}
		der, err = x509.CreateCertificate(rand.Reader, leaf, root, &leafKey.PublicKey, key)
		if err != nil {
			t.Fatal(err)
		}
		return root, tls.Certificate{Certificate: [][]byte{der}, PrivateKey: leafKey}
	}
	rootA, clientA := makeIdentity("A")
	rootB, clientB := makeIdentity("B")
	pool := func(roots ...*x509.Certificate) *x509.CertPool {
		p := x509.NewCertPool()
		for _, root := range roots {
			p.AddCert(root)
		}
		return p
	}

	for _, version := range []uint16{tls.VersionTLS12, tls.VersionTLS13} {
		t.Run(tls.VersionName(version), func(t *testing.T) {
			ca := new(realmRotatingCA)
			initialPool := pool(rootA)
			ca.pool.Store(initialPool)
			auth := &ClientAuthentication{ca: ca, Mode: "require_and_verify"}
			policyConfig := &tls.Config{
				Certificates: []tls.Certificate{clientA},
				MinVersion:   version, MaxVersion: version,
			}
			if err := auth.ConfigureTLSConfig(policyConfig); err != nil {
				t.Fatal(err)
			}
			ctx, cancel := caddy.NewContext(caddy.Context{Context: context.Background()})
			defer cancel()
			policies := ConnectionPolicies{&ConnectionPolicy{
				TLSConfig: policyConfig, ClientAuthentication: auth,
			}}
			serverConfig := policies.TLSConfig(ctx)
			var calls atomic.Int64
			getConfig := serverConfig.GetConfigForClient
			serverConfig.GetConfigForClient = func(hello *tls.ClientHelloInfo) (*tls.Config, error) {
				calls.Add(1)
				return getConfig(hello)
			}
			serverRoots := pool(rootA)

			handshake := func(t *testing.T, cert *tls.Certificate, wantOK bool) {
				t.Helper()
				server, client := net.Pipe()
				deadline := time.Now().Add(5 * time.Second)
				server.SetDeadline(deadline)
				client.SetDeadline(deadline)
				defer server.Close()
				defer client.Close()
				result := make(chan error, 1)
				go func() {
					result <- tls.Server(server, serverConfig).Handshake()
					server.Close()
				}()
				clientConfig := &tls.Config{
					RootCAs: serverRoots, ServerName: "localhost",
					MinVersion: version, MaxVersion: version,
					// Always present the certificate, even when its CA is no
					// longer advertised, so rejection tests CA verification.
					GetClientCertificate: func(*tls.CertificateRequestInfo) (*tls.Certificate, error) {
						if cert == nil {
							return &tls.Certificate{}, nil
						}
						return cert, nil
					},
				}
				clientErr := tls.Client(client, clientConfig).Handshake()
				client.Close()
				serverErr := <-result
				if wantOK && (serverErr != nil || clientErr != nil) {
					t.Fatalf("expected accepted handshake: server=%v client=%v", serverErr, clientErr)
				}
				if !wantOK && serverErr == nil {
					t.Fatalf("server accepted untrusted or missing client certificate (client=%v)", clientErr)
				}
				if !wantOK && cert != nil {
					var unknownAuthority x509.UnknownAuthorityError
					if !errors.As(serverErr, &unknownAuthority) {
						t.Fatalf("expected unknown authority rejection, got %v", serverErr)
					}
				}
			}

			for _, phase := range []struct {
				name string
				pool *x509.CertPool
				a, b bool
			}{
				{"A", initialPool, true, false},
				{"A+B", pool(rootA, rootB), true, true},
				{"B", pool(rootB), false, true},
				{"empty", pool(), false, false},
			} {
				t.Run(phase.name, func(t *testing.T) {
					ca.pool.Store(phase.pool)
					// Previously returned configs must keep their own snapshot.
					previous, err := getConfig(&tls.ClientHelloInfo{})
					if err != nil {
						t.Fatal(err)
					}
					if previous == policyConfig || previous.ClientCAs != phase.pool {
						t.Error("handshake must receive a clone with the current CA pool")
					}
					for _, tc := range []struct {
						name string
						cert *tls.Certificate
						ok   bool
					}{{"clientA", &clientA, phase.a}, {"clientB", &clientB, phase.b}, {"no-client-cert", nil, false}} {
						t.Run(tc.name, func(t *testing.T) {
							t.Parallel()
							handshake(t, tc.cert, tc.ok)
						})
					}
					t.Cleanup(func() {
						if policyConfig.ClientCAs != initialPool {
							t.Error("published policy config was mutated")
						}
						ca.pool.Store(pool())
						if previous.ClientCAs != phase.pool {
							t.Error("previously returned config was mutated")
						}
					})
				})
			}
			if calls.Load() != 12 {
				t.Fatalf("real handshakes called GetConfigForClient %d times, want 12", calls.Load())
			}
		})
	}
}
