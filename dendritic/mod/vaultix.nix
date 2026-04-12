{ inputs, self, ... }:
{
  flake.vaultix = {
    nodes =
      let
        inherit (inputs.nixpkgs.lib) filterAttrs elem;
      in
      filterAttrs (
        n: _:
        !elem n [
          # "yidhra"
          "resq"
          "livecd"
          "bootstrap"
          "nodens"
          # "hastur"
          # "kaambl"
        ]
      ) self.nixosConfigurations;
    identity = self + "/sec/age-yubikey-identity-7d5d5540.txt.pub";
    extraRecipients = [ self.data.keys.ageKey ];
    defaultSecretDirectory = "./sec";
    cache = "./sec/.cache";
  };
}
