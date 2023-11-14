set shell := ["nu", "-c"]

alias cp := copy
alias b := build
alias d := deploy
alias h := home-active

host := `hostname`

default:
	@echo "\
	cp target [data,]         # copy agenix encrypted files\n\
	b [host,]                 # build nixosConfigurations toplevel\n\
	d [target,] builder mode  # deploy into target\n\
	h                         # build and activate home\n\
	"
copy target datas="[hastur,azasos,kaambl,yidhra,nodens]":
	{{datas}} | each { |i| (nix copy --substitute-on-destination --to 'ssh://{{target}}' (nix eval --raw $'.#nixosConfigurations.($i).config.age.rekey.derivation') -vvv) }

build hosts:
	{{hosts}} | each { |i| nom build $'.#nixosConfigurations.(ssh $i hostname).config.system.build.toplevel' }

deploy targets builder="localhost" mode="switch":
	{{targets}} | each { |target| nixos-rebuild --target-host $target --build-host {{builder}} {{mode}} --use-remote-sudo --flake $'.#(ssh $target hostname)' }

home-active builder="rha0":
	if {{host}} == "kaambl" { just build-home-remotely (`whoami`) {{builder}} } else { just build-home (`whoami`) }
	./result/activate

build-home-remotely user builder:
	nom build '.#homeConfigurations.{{user}}.activationPackage' --builders 'ssh://{{builder}} x86_64-linux'
build-home user:
	nom build '.#homeConfigurations.{{user}}.activationPackage'
