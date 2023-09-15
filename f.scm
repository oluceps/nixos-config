":"; exec mzscheme -r $0 "$@"

(require (lib "process.ss"))

(define (copy-secrets args)
     (system (string-append "nix copy --substitute-on-destination --to ssh://"
                            (vector-ref args 1)
                            " "
                            "$(nix eval --raw .#nixosConfigurations."
                            (vector-ref args 2)
                            ".config.age.rekey.derivation)")))

(define (prepare-update args)
  (let* ((cmd (string-append "nix build .#nixosConfigurations."
                             (vector-ref args 1)
                             ".config.system.build.toplevel --log-format internal-json -v 2>&1 | nom --json")))
                             (system cmd)))
(define args (current-command-line-arguments))

(match (vector-ref args 0)
  ["cp" (copy-secrets args)]
  ["pre" (prepare-update args)])
