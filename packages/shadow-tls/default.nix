{ lib
, fetchFromGitHub
, pkgs
#, fenix
}:

let
#  fenix = import
#    (fetchTarball {
#      url = "https://github.com/nix-community/fenix/archive/main.tar.gz";
#      sha256 = "sha256:1l0j43iks97lk70s3zb43vfbbjf1j1x2nrpbfx559xfv0ivn45br";
#    })
#    { };
  rustPlatform = pkgs.makeRustPlatform { inherit (pkgs.fenix.minimal) cargo rustc; };
in
rustPlatform.buildRustPackage rec{
  pname = "shadow-tls";
  version = "0.2.3";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "ihciah";
    repo = pname;
    sha256 = "sha256-jNXXICQf7ukX+lU4pjOf5OL99ymKVxkq52IcZPWQY8E=";
  };

  cargoSha256 = "sha256-dV5MKsmpSxQxKUe6WKf6IfNQo/YGD9JYhWu7Rv58nN4=";

  meta = with lib; {
    homepage = "https://github.com/ihciah/shadow-tls";
    description = ''
      A proxy to expose real tls handshake to the firewall.
    '';
    #    maintainers = with maintainers; [ oluceps ];
  };
}
