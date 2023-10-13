{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "arch-run";
  text = ''
    ${pkgs.qemu}/bin/qemu-system-x86_64 \
      -machine accel=kvm,type=q35 \
      -cpu host -smp 22 \
      -m 4G \
      -nographic \
      -device virtio-net-pci,netdev=net0 \
      -netdev user,id=net0,hostfwd=tcp::2225-:22 \
      -drive if=virtio,format=qcow2,file=/var/lib/libvirt/images/Arch-Linux-x86_64-basic-20231001.182377.qcow2 \
      "$@"
  '';
}
