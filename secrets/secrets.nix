let
  riro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  proxy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  hastur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
  elena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  kaambl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1v1/CbbmzLxxlGLb9AQouo+8ID/puQYMfdIQTLgfV+";
  isho = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  users = [ riro elena isho proxy ];
  systems = [ hastur kaambl ];
in
builtins.listToAttrs
  (map
    (name: { name = "${name}.age"; value = { publicKeys = users ++ systems; }; })
    [ "rat" "ss" "sing" "hyst-az" "hyst-do" "hyst-am" "tuic" "naive" "ssh" "wg" "gh-eu" "dae" ])
