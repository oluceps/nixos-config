{ self, inputs, genOverlays, sharedModules, base, lib, data, ... }:
let share = { inherit genOverlays sharedModules base lib; }; in (map (x: import x share)
  ([
    ./hastur
    ./kaambl
  ] ++ map (x: ./. + x) ((map (x: "/" + x) data.withoutHeads)))) ++ [ ./livecd ]
