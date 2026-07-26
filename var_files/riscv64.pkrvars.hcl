architecture = "riscv64"
image_architecture = "riscv-riscv64"
qemu_architecture = "riscv64"
pkg_site_architecture = "riscv64"
machine_type = "virt"
cpu_type = "rv64"
memory = 2048
image_suffix = "disc1.iso"

// Direct kernel boot via OpenSBI fw_jump.bin. firmware and kernel_path are
// absolute paths set by build.sh because they depend on the system.
use_pflash = false

// On riscv64 we declare both block devices ourselves via qemuargs (see
// drive_qemuargs in freebsd.pkr.hcl): the install disk as vtbd0 and the install
// ISO as vtbd1, which the kernel mounts as its cd9660 root. Packer's qemu
// builder replaces ALL of its default -drive switches as soon as qemuargs
// supplies any -drive, so the full set has to be declared together. This keeps
// the ISO a virtio-blk device (vtbd1) - the kernel has virtio_blk but no
// virtio_scsi - while never exposing a /dev/cd0, so has_install_media() stays
// false and provisioning uses custom_pkg_repo.
//
// cdrom_interface stays "virtio" (a pure -drive the override removes cleanly);
// virtio-scsi would emit an unremovable -device scsi-cd that dangles once its
// backing -drive is overridden away.
cdrom_interface = "virtio"

// Boot into single-user mode from the ISO (second virtio-blk device).
kernel_append = "vfs.root.mountfrom=cd9660:/dev/vtbd1 -s"

// RISC-V under TCG boots slowly (~120s). Wait long enough for the single-user
// shell prompt.
boot_wait = "20s"
boot_command_prefix = ["<wait180s><enter><wait15s>"]

// The disc1.iso does not contain distribution .txz files. build.sh downloads
// them and places them in resources/dist/ for Packer's HTTP server to serve.
// BSDINSTALL_DISTSITE is set to the Packer HTTP URL so bsdinstall can fetch
// them without needing DNS.
boot_command_bsdinstall_env = "BSDINSTALL_DISTSITE=http://{{ .HTTPIP }}:{{ .HTTPPort }}/resources/dist "

// Custom package repository for riscv64 (not covered by official FreeBSD mirrors).
custom_pkg_repo = "https://cross-platform-actions.github.io/freebsd-pkg-repo/"

// Use a vc (virtual console) chardev for serial so that VNC keystrokes reach
// the serial port. On RISC-V the only console is uart0 (serial), so without
// this the boot_command would not reach the FreeBSD shell.
serial_qemuargs = [
  ["-chardev", "vc,id=ser0,logfile=serial.log,logappend=on"],
  ["-serial", "chardev:ser0"]
]
