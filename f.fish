#!/usr/bin/env fish

# copy agenix-rekey secrets to remote

function copy_secrets
  switch $argv[2]
      case "hastur"
      nix copy --substitute-on-destination --to ssh://rhs \
        $(nix eval --raw .#nixosConfigurations.hastur.config.age.rekey.derivation)
      case "kaambl"
      nix copy --substitute-on-destination --to ssh://rka \
        $(nix eval --raw .#nixosConfigurations.kaambl.config.age.rekey.derivation)
      case "*"
          echo "unknown host: $argv[2]"
  end
end

function prepare_update
   nix build .#nixosConfigurations.$argv[2].config.system.build.toplevel --log-format internal-json -v 2>&1 | nom --json
end


switch $argv[1]
    case "cp"
        copy_secrets $argv
    case "pre"
        prepare_update $argv
    case "help"
        echo "pre \$host; cp \$host"
    case "*"
        echo "unknown args: $argv"
end

