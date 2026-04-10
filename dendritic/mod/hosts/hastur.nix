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
      self.modules.nixos.coredns
      ./incus.nix
      ./subs.nix
      ./photoprism.nix
    ];
    incus.enable = true;
    incus.user = "riro";
    incus.bridgeAddr = "fdcc:1::1/64";
    subs.enable = true;
    photoprism.enable = true;
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
