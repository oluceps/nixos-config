set shell := ["nu", "-c"]
general_set := "[\"hastur\", \"azasos\", \"kaambl\", \"yidhra\", \"nodens\"]"

alias cp := copy
alias b := build
alias d := deploy

host := `hostname`

copy target data:
	{{general_set}} | each { |i| if ($i in {{data}}) { (nix copy --substitute-on-destination --to 'ssh://{{target}}' (nix eval --raw $'.#nixosConfigurations.($i).config.age.rekey.derivation') -vvv) }}

build hosts:
	{{hosts}} | each { |i| nom build $'.#nixosConfigurations.(ssh $i hostname).config.system.build.toplevel' }

deploy targets builder="localhost" mode="switch":
	{{targets}} | each { |target| nixos-rebuild --target-host $target {{mode}} --use-remote-sudo --flake $'.#(ssh $target hostname)' }
