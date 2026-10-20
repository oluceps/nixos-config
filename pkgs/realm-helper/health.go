package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"time"
)

// healthCommand reports whether the application inside the container answers.
//
// REALM_HEALTH_PORT selects a loopback port and the /health path; otherwise the
// mounted backend socket is probed at /. Any response below 500 counts as
// healthy, which matches the previous Node implementation.
func healthCommand() int {
	client := &http.Client{Timeout: 5 * time.Second}
	url := "http://localhost/"
	if port := os.Getenv("REALM_HEALTH_PORT"); port != "" {
		url = "http://127.0.0.1:" + port + "/health"
	} else {
		socket := backendPath
		client.Transport = &http.Transport{
			DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
				var dialer net.Dialer
				return dialer.DialContext(ctx, "unix", socket)
			},
		}
	}

	response, err := client.Get(url)
	if err != nil {
		return 1
	}
	response.Body.Close()
	if response.StatusCode >= 500 {
		return 1
	}
	return 0
}
