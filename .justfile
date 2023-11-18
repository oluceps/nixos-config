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

home-active builder="rha0":
	if {{host}} == "kaambl" { just build-home-remotely {{me}} {{builder}} } else { just build-home {{me}} }
	./result/activate

build-home-remotely user builder:
	nom build '.#homeConfigurations.{{user}}.activationPackage' --builders 'ssh://{{builder}} x86_64-linux'

build-home user:
	nom build '.#homeConfigurations.{{user}}.activationPackage'

build-livecd:
	nom build .#nixosConfigurations.livecd.config.system.build.isoImage

check:
	nix flake check
	{{nodes}} | each { |x| nix eval --raw $'.#nixosConfigurations.($x).config.system.build.toplevel' --show-trace }

clean:
	git clean -f
