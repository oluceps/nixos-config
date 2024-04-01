{ lib, user, inputs, ... }: {
  deployment = {
    targetHost = "somehost.tld";
    targetPort = 22;
    targetUser = user;
  };

  imports =
    lib.sharedModules ++ [

      inputs.disko.nixosModules.default
      ./hardware.nix
      ./network.nix
      ./rekey.nix
      ./spec.nix
      ../../age.nix
      ../../packages.nix
      ../../misc.nix
      ../../users.nix
    ];
}
