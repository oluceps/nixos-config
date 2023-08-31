#!/usr/bin/env fish

# copy agenix-rekey secrets to remote

nix copy --substitute-on-destination --to ssh://rhs \
  $(nix eval --raw .#nixosConfigurations.kaambl.config.age.rekey.derivation)