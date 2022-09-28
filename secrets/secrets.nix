let
  riro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  hastur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
  users = [riro];
  systems = [hastur];
  

in
{
  "ssconf.age".publicKeys = users ++ systems;
  "sing.age".publicKeys = users ++ systems;
}
