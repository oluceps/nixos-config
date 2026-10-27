package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"time"
)

// Libraries using AI_ADDRCONFIG, including CacheableLookup with Node's socket
// options, ignore all DNS answers if the namespace has only loopback. A dummy
// interface advertises both address families without providing an external
// link or default route. No physical/veth/TUN interface is accepted here.
func (c *controller) setupNetwork(ctx context.Context, ns *os.File) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	ip := func(args ...string) ([]byte, error) {
		command := exec.CommandContext(ctx, c.config.NamespaceTool, append([]string{"--net=/proc/self/fd/3", "--", c.config.NetworkTool}, args...)...)
		command.ExtraFiles = []*os.File{ns}
		command.Dir = "/"
		command.Env = []string{"PATH=/run/current-system/sw/bin"}
		out, e := command.CombinedOutput()
		if e != nil {
			return nil, fmt.Errorf("private namespace ip %v: %w: %s", args, e, out)
		}
		return out, nil
	}
	raw, e := ip("-d", "-j", "link", "show")
	if e != nil {
		return e
	}
	var links []struct {
		Name string `json:"ifname"`
		Info struct {
			Kind string `json:"info_kind"`
		} `json:"linkinfo"`
	}
	if e = json.Unmarshal(raw, &links); e != nil {
		return e
	}
	exists := false
	for _, l := range links {
		if l.Name == "lo" {
			continue
		}
		if l.Name != "realm0" || l.Info.Kind != "dummy" {
			return fmt.Errorf("refusing namespace with external-capable interface %s", l.Name)
		}
		exists = true
	}
	// Also reject configured default routes, even when they point at a dummy.
	for _, family := range []string{"-4", "-6"} {
		b, e := ip(family, "-j", "route", "show", "table", "all")
		if e != nil {
			return e
		}
		var routes []struct {
			Destination string `json:"dst"`
		}
		if e = json.Unmarshal(b, &routes); e != nil {
			return e
		}
		for _, r := range routes {
			if r.Destination == "default" {
				return errors.New("private namespace must not have a default route")
			}
		}
	}
	if !exists {
		if _, e = ip("link", "add", "realm0", "type", "dummy"); e != nil {
			return e
		}
	}
	for _, args := range [][]string{{"-4", "address", "replace", "192.0.2.254/32", "dev", "realm0"}, {"-6", "address", "replace", "2001:db8::ffff/128", "dev", "realm0", "nodad"}, {"link", "set", "realm0", "up"}} {
		if _, e = ip(args...); e != nil {
			return e
		}
	}
	return nil
}
