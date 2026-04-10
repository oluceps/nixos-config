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
      # self.modules.nixos.repack
    ];
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
