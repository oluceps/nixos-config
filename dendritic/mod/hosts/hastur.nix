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
      self.modules.nixos.coredns
      self.modules.nixos.incus
      self.modules.nixos.subs
      self.modules.nixos.photoprism
    ];
    identity.user = "riro";
    repack.incus.enable = true;
    repack.incus.bridgeAddr = "fdcc:1::1/64";
    repack.subs.enable = true;
    repack.photoprism.enable = true;
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
