inputs:
let data = (import ./lib.nix inputs).data; in
([
  ./hastur
  ./kaambl
]
++ map (x: ./. + x) ((map (x: "/" + x) data.withoutHeads))
)
++ [ ./livecd ]
