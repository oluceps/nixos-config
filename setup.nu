#!/usr/bin/env -S nu --stdin

def copy_secrets [a: string, h: string] {
 (nix copy --substitute-on-destination --to $'ssh://($a)'
   (nix eval --raw $'.#nixosConfigurations.($h).config.age.rekey.derivation') -vvv)
}

def prepare_configuration [x: string] {
  nix build $".#nixosConfigurations.($x).config.system.build.toplevel --log-format internal-json -v 2>&1 | nom --json"
}

def main [x: string, y: string = "", z: string = ""] {
  const general_set = ["hastur" "azasos" "kaambl" "yidhra" "nodens"]
  
  if $x == 'cp' {
    if $z == 'all' {
      $general_set | each { |i| copy_secrets $y $i }
      return
    }
    (ssh $y hostname) | copy_secrets $y $in
    print completed.
  }

  if $x == 'pre' {
    if $y == 'all' {
      $general_set | each { |i| prepare_configuration $i }
    }
  }

  if $x == 'help' {
    print 'cp <ssh alias>' 'cp <ssh alias> all' 'pre <hostname>'
  }
}
