{
  self,
  ...
}:
{
  configurations.nixos.hastur.module = {
    imports =
      with self.modules;
      (
        (with generic; [
          data
          fn
        ])
        ++ (with nixos; [
          identity
          openssh
          fail2ban
          scrutiny
          userborn-subid
          earlyoom
          incus
          dae
          vaultix
          custom-modules
        ])
      );

    identity.user = "root";
    incus.bridgeAddr = "fdcc:1::1/64";

    systemd.sysusers.enable = true;

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
