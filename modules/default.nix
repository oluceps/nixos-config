[
  ./ss
  ./rathole
  ./clash-m
  ./tuic
  ./btrbk
  ./naive
  ./sundial
  ./dae
]
++ # Hysteria configs
(map (import ./hysteria) [
  "hyst-az"
  "hyst-do"
  "hyst-am"
])
++ [ (import ./sing-box { }) ]
