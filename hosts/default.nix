{ self, inputs, genOverlays, sharedModules, base, lib, data, ... }:
let share = { inherit genOverlays sharedModules base lib; }; in [
  (import
    ./hastur
    share)
  (import
    ./kaambl
    share)
  (import
    ./yidhra
    share)
  (import
    ./azasos
    share)
  (import
    ./nodens
    share)

  ./livecd

]
