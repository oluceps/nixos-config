#!/usr/bin/env nu

const map = [
    [name, addr];
		[hastur, riro@10.0.2.2],
		[kaambl, elen@localhost],
		[eihort, elen@10.0.2.6],
		[nodens, dgs],
		# [azasos, tcs],
		# [abhoth, abh],
		[colour, col],
]

const hosts = $map.name

let get_map = { |per| $map | filter {|i| $i.name == $per } }

let get_addr = { |b| do $get_map $b | $in.addr.0 }

def "main p" [
  target: string
  nodes?: list<string> = $hosts
] {
  let drv = { |name| nix eval --raw $'.#nixosConfigurations.($name).config.age.rekey.derivation' }

  let push = { |t_addr, path| nix copy --substitute-on-destination --to $'ssh://($t_addr)' $path -vvv }

  let target_addr = do $get_addr $target

  $map |
  par-each { 
  |per|
     let name = $per.name
     if $name in $nodes {

       do $push ($target_addr) (do $drv $per.name) 

     }
   }
}

def "main b" [
  nodes?: list<string> = $hosts
  --builder (-b): string = "hastur"
] {

  let target_addr = do $get_addr $builder

  $map |
  par-each { 
  |per|
     let name = $per.name
     if $name in $nodes {
       nom build $'.#nixosConfigurations.($name).config.system.build.toplevel' --builders $"($target_addr)"
     }
   }

}

def "main d" [
  nodes?: list<string> = $hosts
  mode?: string = "switch"
  --builder (-b): string = "hastur"
] {

  let builder_addr = do $get_addr $builder

  $map |
  par-each {
  |per|
     let name = $per.name
     if $name in $nodes {
       nixos-rebuild $mode --flake $'.#($name)' --target-host (do $get_addr $name) --build-host $"($builder_addr)" --use-remote-sudo
     }
   }

}

def main [] { }
