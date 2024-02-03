set shell := ["nu", "-c"]


alias f := fetch-secret
alias b := build-host
alias d := deploy
alias h := home-active
alias c := check
alias p := push-secret

host := `hostname`
me   := `whoami`
loc := "/home/riro/Src/nixos"

nodes := `nix eval --impure --expr "with builtins; attrNames (getFlake "/home/riro/Src/nixos").nixosConfigurations"`

# now `all` produces false while which in list.
filter := '''
		filter {|o| [ nixos ] | all { |i| $o != $i } }
		'''

map := '''
	{
		hastur: riro@hastur,
		kaambl: elen@kaambl,
		nodens: dgs,
		azasos: tcs,
		abhoth: abh,
		colour: col
	}
'''



default:
  @just --choose

help:
	@echo "\
	p target [data,]          # push agenix encrypted files\n\
	f source [data,]          # fetch agenix encrypts from remote\n\
	b [host,]                 # build nixosConfigurations toplevel\n\
	d [target,] builder mode  # deploy into target\n\
	h                         # build and activate home\n\
	c                         # check and eval\n\
	"
push-secret target="hastur" datas=nodes:
	{{datas}} | {{filter}} | par-each { |i| {{map}} | (nix copy --substitute-on-destination --to $'ssh://(($in).{{target}})' (nix eval --raw $'{{loc}}#nixosConfigurations.($i).config.age.rekey.derivation') -vvv) }

fetch-secret source="kaambl" datas=nodes:
	{{datas}} | {{filter}} | par-each { |i| {{map}} | (ssh {{source}} -t $"nix eval --raw {{loc}}#nixosConfigurations.($i).config.age.rekey.derivation") | (nix copy --substitute-on-destination --from 'ssh://{{source}}' $in -vvv )}

build-host hosts=nodes:
	{{hosts}} | {{filter}} | par-each { |i| nom build $'{{loc}}#nixosConfigurations.($i).config.system.build.toplevel' }

deploy targets=nodes builder="hastur" mode="switch":
	#!/usr/bin/env nu
	def get_map [ k: string ] { {{map}} | get $k }
	{{targets}} | {{filter}} | par-each { |target| nixos-rebuild --target-host (get_map $target) --build-host (get_map {{builder}}) {{mode}} --use-remote-sudo --flake $'{{loc}}#($target)' }

home-active +args="":
	nom build '.#homeConfigurations.{{me}}.activationPackage' {{args}}
	./result/activate

build-livecd:
	nom build .#nixosConfigurations.nixos.config.system.build.isoImage

check +args="":
	nix flake check {{args}}

slow-action +args="": rekey check overwrite-s3
	sudo nixos-rebuild switch

upgrade: rekey
	nix flake update --commit-lock-file
	sudo nixos-rebuild switch

rekey:
	agenix rekey

overwrite-s3:
	mc mirror --overwrite --remove /home/{{me}}/Sec/ r2/sec/Sec
	mc mirror --overwrite --remove /etc/nixos/sec/ r2/sec/credentials

overwrite-local:
	mc mirror --overwrite --remove r2/sec/Sec /home/{{me}}/Sec/

clean:
	git clean -f
