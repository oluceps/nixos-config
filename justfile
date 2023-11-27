set shell := ["nu", "-c"]


alias f := fetch-secret
alias b := build-host
alias d := deploy
alias h := home-active
alias c := check
alias p := push-secret

host := `hostname`
me   := `whoami`

nodes := `nix eval --impure --expr "with builtins; attrNames (getFlake \"/etc/nixos\").nixosConfigurations"`

filter := '''
		where $it != "nixos"
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
push-secret target="rha" datas=nodes:
	{{datas}} | {{filter}} | each { |i| (nix copy --substitute-on-destination --to 'ssh://{{target}}' (nix eval --raw $'.#nixosConfigurations.($i).config.age.rekey.derivation') -vvv) }

fetch-secret source="kmb" datas=nodes:
	{{datas}} | {{filter}} | each { |i| (ssh {{source}} -t $"nix eval --raw /etc/nixos#nixosConfigurations.($i).config.age.rekey.derivation") | (nix copy --substitute-on-destination --from 'ssh://{{source}}' $in -vvv )}

build-host hosts=nodes:
	{{hosts}} | {{filter}} | each { |i| nom build $'.#nixosConfigurations.($i).config.system.build.toplevel' }

deploy targets=nodes builder="localhost" mode="switch":
	{{targets}} | {{filter}} | each { |target| nixos-rebuild --target-host $target --build-host {{builder}} {{mode}} --use-remote-sudo --flake $'.#($target)' }

home-active +args="":
	nom build '.#homeConfigurations.{{me}}.activationPackage' {{args}}
	./result/activate

build-livecd:
	nom build .#nixosConfigurations.nixos.config.system.build.isoImage

check +args="":
	nix flake check {{args}}
	{{nodes}} | each { |x| nix eval --raw $'.#nixosConfigurations.($x).config.system.build.toplevel' --show-trace }

slow-action +args="":
	agenix rekey
	just c
	just overwrite-s3
	sudo nixos-rebuild switch
	just h


overwrite-s3:
	mc mirror --overwrite --remove /home/{{me}}/Sec/ r2/sec/Sec
	mc mirror --overwrite --remove /etc/nixos/sec/ r2/sec/credentials

overwrite-local:
	mc mirror --overwrite --remove r2/sec/Sec /home/{{me}}/Sec/

clean:
	git clean -f
