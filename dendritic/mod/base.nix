{ self, ... }:
{
  flake.modules.nixos.base = {
    imports = with self.modules.nixos; [
      fish
      bash
      nix
      cut
      base-pkgs
      virt
      starship
      env
      pki
      security
      # perlless
    ];
  };
}
