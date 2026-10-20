package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"
	_ "github.com/caddyserver/caddy/v2/modules/standard"
	_ "github.com/mholt/caddy-l4"
	_ "nyaw.xyz/caddy-l4-srv"
)

func main() { caddycmd.Main() }
