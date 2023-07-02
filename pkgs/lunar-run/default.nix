{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "lunar-run";
  text = ''
      ${pkgs.qemu}/bin/qemu-system-x86_64 \
        -machine virt -nographic -m 8G -smp 22 \
        -device virtio-net-device,netdev=usernet \
        -netdev user,id=usernet,hostfwd=tcp::12054-:22 \
        -device qemu-xhci -usb -device usb-kbd -device usb-tablet \
        -drive file=/var/lib/libvirt/images/lunar-server-cloudimg-amd64.img,format=raw,if=virtio
        "$@"
  '';
}
