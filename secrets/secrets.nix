let
  riro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  hastur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBaeKFjaE611RF7iHQzl+xfWxrIPA1+d10/qh2IhTq4l";
  elena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEv3S53gBU3Hqvr5o5g+yrn1B7eiaE5Y/OIFlTwU+NEG";
  kaambl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1v1/CbbmzLxxlGLb9AQouo+8ID/puQYMfdIQTLgfV+";
  users = [ riro elena ];
  systems = [ hastur kaambl ];


in
{
  "ssconf.age".publicKeys = users ++ systems;
  "sing.age".publicKeys = users ++ systems;
}
