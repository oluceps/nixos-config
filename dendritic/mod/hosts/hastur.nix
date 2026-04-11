{
  config,
  self,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  configurations.nixos.hastur.module = {
    imports = [
      self.modules.generic.data
      self.modules.generic.fn
      self.modules.nixos.identity
      self.modules.nixos.openssh
      self.modules.nixos.fail2ban
      self.modules.nixos.scrutiny
      self.modules.nixos.userborn-subid
      self.modules.nixos.earlyoom
      self.modules.nixos.incus
    ];

    identity.user = "riro";

    incus.bridgeAddr = "fdcc:1::1/64";

    users.users.riro = {
      isNormalUser = true;
      group = "riro";
      extraGroups = [ "wheel" ];
    };
    users.groups.riro = { };

    networking.hostName = "hastur";
    nixpkgs.hostPlatform = "x86_64-linux";
    boot.loader.grub.devices = [ "nodev" ];
    fileSystems = {
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
      };
    };
  };
}
