set shell := ["nu", "-c"]

alias cp := copy
alias f := fetch
alias b := build
alias d := deploy
alias h := home-active

host := `hostname`

nodes := "[hastur,azasos,kaambl,nodens]"

default:
	@echo "\
	cp target [data,]         # copy agenix encrypted files\n\
	f source [data,]          # fetch agenix encrypts from remote\n\
	b [host,]                 # build nixosConfigurations toplevel\n\
	d [target,] builder mode  # deploy into target\n\
	h                         # build and activate home\n\
	"
copy target datas=nodes:
	{{datas}} | each { |i| (nix copy --substitute-on-destination --to 'ssh://{{target}}' (nix eval --raw $'.#nixosConfigurations.($i).config.age.rekey.derivation') -vvv) }

fetch source="kmb" datas=nodes:
	{{datas}} | each { |i| (ssh {{source}} -t $"nix eval --raw /etc/nixos#nixosConfigurations.($i).config.age.rekey.derivation") | (nix copy --substitute-on-destination --from 'ssh://{{source}}' $in -vvv )}

build hosts=nodes:
	{{hosts}} | each { |i| nom build $'.#nixosConfigurations.($i).config.system.build.toplevel' }

deploy targets=nodes builder="localhost" mode="switch":
	{{targets}} | each { |target| nixos-rebuild --target-host $target --build-host {{builder}} {{mode}} --use-remote-sudo --flake $'.#($target)' }

home-active builder="rha0":
	if {{host}} == "kaambl" { just build-home-remotely (`whoami`) {{builder}} } else { just build-home (`whoami`) }
	./result/activate

build-home-remotely user builder:
	nom build '.#homeConfigurations.{{user}}.activationPackage' --builders 'ssh://{{builder}} x86_64-linux'
build-home user:
	nom build '.#homeConfigurations.{{user}}.activationPackage'
