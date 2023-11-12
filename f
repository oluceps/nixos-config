#!/usr/bin/env -S nu --stdin

const general_set = ["hastur" "azasos" "kaambl" "yidhra" "nodens"]
 
def copy_secrets [a: string, h: string] {
 (nix copy --substitute-on-destination --to $'ssh://($a)'
   (nix eval --raw $'.#nixosConfigurations.($h).config.age.rekey.derivation') -vvv)
}

def prepare_configuration [x: string] {
  nom build $'.#nixosConfigurations.($x).config.system.build.toplevel'
}

def rekey [x, y, z] {
  if $x == 'cp' {
    if $z == 'all' {
      $general_set | each { |i| copy_secrets $y $i }
      return
    }
    (ssh $y hostname) | copy_secrets $y $in
    print completed.
  }
}

def pre [x, y, z] {
  if $x == 'pre' {
    if $y == 'all' {
      $general_set | each { |i| prepare_configuration $i }
    }
  }
}

def deploy [t: string, b: string = "", m: string = ""] {
  let hostname = (ssh $t hostname)
  nixos-rebuild --target-host $t $m --use-remote-sudo --flake $'.#($hostname)'
}
def main [x: string = "", y: string = "", z: string = "", a: string = "switch"] {
  cd '/etc/nixos'
  
  rekey $x $y $z

  pre $x $y $z

  if $x == 'd' {
    deploy $y $z $a
  } 

  if $x == 'y' {
    $general_set | each { |i| deploy $i $z $a }
  }

  if $x == 'help' or $x == 'h' or $x == "" {
    print 'cp <ssh alias>' 'cp <ssh alias> all' 'pre <hostname>' 'd <ssh alias> <build host alias> <switch>' 'y <build host alias> <switch> # build and deploy all'
  }
  cd -
}
