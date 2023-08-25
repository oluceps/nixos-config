#!/usr/bin/env fish

# copy agenix-rekey secrets to remote

nix copy --substitute-on-destination --to ssh://$argv[1] \
  $(nix eval --raw .#nixosConfigurations.kaambl.config.age.rekey.derivation)