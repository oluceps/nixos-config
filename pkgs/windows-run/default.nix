{pkgs,...}:
pkgs.writeShellApplication {
  name = "windows-run";
  text = ''
    ${pkgs.qemu.override { smbdSupport = true; hostCpuOnly = true; }}/bin/qemu-system-x86_64 \
      -nodefaults \
      -machine q35 -accel kvm -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
      -smp sockets=1,cores=6 -m 8G \
      -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
      -vga qxl \
      -display gtk \
      -nic user,model=virtio-net-pci,smb="$HOME/Downloads" \
      -usb -device usb-tablet \
      -drive if=virtio,file=/var/lib/libvirt/images/win10.qcow2,aio=io_uring \
      "$@"
  '';
}
