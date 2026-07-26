variable "os_version" {
  type        = string
  description = "The version of the operating system to download and install"
}

variable "architecture" {
  default     = "amd64"
  type        = string
  description = "The architecture of CPU to use when building"
}

variable "image_architecture" {
  default     = "amd64"
  type        = string
  description = "The name of the architecture used by the ISO image"
}

variable "qemu_architecture" {
  default     = "x86_64"
  type        = string
  description = "The name of the architecture in the QEMU binary"
}

variable "pkg_site_architecture" {
  type        = string
  description = "The name of the architecture used by the pkg site: http://pkg.freebsd.org"
}

variable "machine_type" {
  default     = "pc"
  type        = string
  description = "The type of machine to use when building"
}

variable "cpu_type" {
  default     = "qemu64"
  type        = string
  description = "The type of CPU to use when building"
}

variable "memory" {
  default     = 4096
  type        = number
  description = "The amount of memory to use when building the VM in megabytes"
}

variable "cpus" {
  default     = 2
  type        = number
  description = "The number of cpus to use when building the VM"
}

variable "disk_size" {
  default     = "12G"
  type        = string
  description = "The size in bytes of the hard disk of the VM"
}

variable "checksum" {
  type        = string
  description = "The checksum for the virtual hard drive file"
}

variable "root_password" {
  default     = "vagrant"
  type        = string
  description = "The password for the root user"
}

variable "secondary_user_username" {
  default     = "vagrant"
  type        = string
  description = "The name for the secondary user"
}

variable "headless" {
  default     = false
  description = "When this value is set to `true`, the machine will start without a console"
}

variable "use_default_display" {
  default     = true
  type        = bool
  description = "If true, do not pass a -display option to qemu, allowing it to choose the default"
}

variable "display" {
  default     = "cocoa"
  description = "What QEMU -display option to use"
}

variable "accelerator" {
  default     = "tcg"
  type        = string
  description = "The accelerator type to use when running the VM"
}

variable "firmware" {
  type        = string
  description = "The firmware file to be used by QEMU"
}

variable "use_pflash" {
  default     = false
  type        = bool
  description = "If true, the firmware is provided through a pflash drive instead of -bios"
}

variable "efi_boot" {
  default     = false
  type        = bool
  description = "If true, enable UEFI boot using efi_firmware_code and efi_firmware_vars as pflash drives."
}

variable "efi_firmware_code" {
  default     = ""
  type        = string
  description = "Path to the CODE part of the EFI firmware (read-only pflash). Used when efi_boot is true."
}

variable "efi_firmware_vars" {
  default     = ""
  type        = string
  description = "Path to the VARS part of the EFI firmware. Packer copies this to the output and uses it as a writable pflash."
}

variable "image_suffix" {
  default     = "dvd1.iso"
  type        = string
  description = "The suffix of the ISO image file name (e.g. dvd1.iso, disc1.iso)"
}

variable "boot_wait" {
  default     = "6s"
  type        = string
  description = "Time to wait before typing the boot command"
}

variable "boot_command_prefix" {
  default     = ["2<wait30s>"]
  type        = list(string)
  description = "Architecture-specific boot command prefix. Executed before the common installer commands. Default boots single user on the standard FreeBSD boot menu."
}

variable "boot_command_setup" {
  default     = []
  type        = list(string)
  description = "Architecture-specific boot commands inserted between mdmfs and dhclient. Used e.g. to make /etc writable on read-only root filesystems."
}

variable "boot_command_bsdinstall_env" {
  default     = ""
  type        = string
  description = "Extra environment variables prepended to the bsdinstall command in boot_command. Use for architecture-specific overrides like BSDINSTALL_DISTSITE."
}

variable "kernel_path" {
  default     = ""
  type        = string
  description = "Path to a kernel binary for QEMU -kernel direct boot. When empty, QEMU boots via firmware."
}

variable "kernel_append" {
  default     = ""
  type        = string
  description = "Kernel command line for QEMU -append (only used when kernel_path is set)."
}

variable "serial_qemuargs" {
  default     = [["-chardev", "file,id=ser0,path=serial.log"], ["-serial", "chardev:ser0"]]
  type        = list(list(string))
  description = "QEMU arguments for the serial port. Override to use a vc chardev for VNC-accessible serial."
}

variable "custom_pkg_repo" {
  default     = ""
  type        = string
  description = "Base URL of a custom FreeBSD pkg repository. Used when no upstream pkg repository or install media is available (e.g. riscv64). The ABI path (e.g. FreeBSD:15:riscv64) is appended automatically by pkg."
}

variable "extra_qemuargs" {
  default     = []
  type        = list(list(string))
  description = "Additional QEMU arguments appended to the default qemuargs."
}

variable "cdrom_interface" {
  default     = "ide"
  type        = string
  description = "Interface for the ISO drive (ide, scsi, virtio, virtio-scsi, usb)."
}

variable "iso_local_path" {
  default     = ""
  type        = string
  description = "Absolute path to a local ISO to attach as a second virtio-blk device (vtbd1). Used on riscv64 so the kernel can mount the install media as its cd9660 root. Packer's own boot ISO is attached separately via cdrom_interface."
}

locals {
  vm_name  = "freebsd-${var.os_version}-${var.architecture}.qcow2"
  iso_path = "ISO-IMAGES/${var.os_version}/FreeBSD-${var.os_version}-RELEASE-${var.image_architecture}-${var.image_suffix}"

  // When kernel_path is set, add -kernel and -append for direct kernel boot.
  kernel_qemuargs = var.kernel_path != "" ? [
    ["-kernel", var.kernel_path],
    ["-append", var.kernel_append]
  ] : []

  // When iso_local_path is set (riscv64), declare all block devices ourselves.
  // Packer's qemu builder replaces ALL of its default -drive switches the moment
  // qemuargs supplies any -drive, so the install disk has to be re-declared too,
  // matching the qcow2 Packer creates at output_directory/vm_name.
  //   vtbd0 = install disk (index 0)
  //   vtbd1 = install ISO (index 1), mounted as the cd9660 root (kernel_append)
  drive_qemuargs = var.iso_local_path != "" ? [
    ["-drive", "file=output/${local.vm_name},if=virtio,index=0,cache=writeback,discard=ignore,format=qcow2"],
    ["-drive", "file=${var.iso_local_path},if=virtio,index=1,media=cdrom"]
  ] : []
}

source "qemu" "qemu" {
  machine_type = "${var.machine_type}"
  cpus         = var.cpus
  memory       = var.memory
  net_device   = "virtio-net"

  disk_compression = true
  disk_interface   = "virtio"
  disk_size        = var.disk_size
  format           = "qcow2"
  cdrom_interface  = var.cdrom_interface

  headless            = var.headless
  use_default_display = var.use_default_display
  display             = var.display
  accelerator         = "none" // we manually specify multiple accelerators below
  qemu_binary         = "qemu-system-${var.qemu_architecture}"
  firmware            = var.firmware
  use_pflash          = var.use_pflash
  efi_boot            = var.efi_boot
  efi_firmware_code   = var.efi_firmware_code
  efi_firmware_vars   = var.efi_firmware_vars

  boot_wait = var.boot_wait

  boot_command = concat(var.boot_command_prefix, [
    "<enter><wait10>",
    "mdmfs -s 100m md1 /tmp<enter><wait>",
    ], var.boot_command_setup, [
    "dhclient -l /tmp/dhclient.leases -p /tmp/dhclient.pid vtnet0<enter><wait5>",
    "fetch -o /tmp/installerconfig http://{{.HTTPIP}}:{{.HTTPPort}}/resources/installerconfig<enter><wait>",
    "${var.boot_command_bsdinstall_env}",
    "ROOT_PASSWORD=${var.root_password} ",
    "bsdinstall script /tmp/installerconfig && reboot<enter>"
  ])

  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout  = "10000s"

  qemuargs = concat([
    ["-cpu", var.cpu_type],
    ["-boot", "strict=off"],
    ["-monitor", "none"],
    ["-accel", "hvf"],
    ["-accel", "kvm"],
    ["-accel", "tcg"],
  ], var.serial_qemuargs, local.kernel_qemuargs, local.drive_qemuargs, var.extra_qemuargs)

  iso_checksum = var.checksum

  // When build.sh has already downloaded the ISO locally (riscv64, where it is
  // also extracted/attached via iso_local_path), point Packer at that same file
  // so it reuses it instead of downloading a second, unused copy. The ISO
  // attached to the VM comes from drive_qemuargs, so Packer's copy is never
  // used for the build; this just avoids the redundant download. Empty (the
  // default) on other architectures, where Packer downloads as usual.
  iso_target_path = var.iso_local_path

  iso_urls = [
    "https://ftp.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "https://archive.freebsd.org/old-releases/${local.iso_path}",
    "http://ftp4.se.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp2.de.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "https://ftp.lv.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp4.us.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp.at.freebsd.org/pub/FreeBSD/releases/${local.iso_path}"
  ]

  http_directory   = "."
  output_directory = "output"
  shutdown_command = "shutdown -p now"
  vm_name          = local.vm_name
}

packer {
  required_plugins {
    qemu = {
      version = "~> 1.1.3"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

build {
  sources = ["qemu.qemu"]

  provisioner "shell" {
    script          = "resources/provision.sh"
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "SECONDARY_USER_USERNAME=${var.secondary_user_username}",
      "OS_VERSION=${var.os_version}",
      "PKG_SITE_ARCHITECTURE=${var.pkg_site_architecture}",
      "CUSTOM_PKG_REPO=${var.custom_pkg_repo}"
    ]
  }

  provisioner "shell" {
    script          = "resources/custom.sh"
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "SECONDARY_USER_USERNAME=${var.secondary_user_username}"
    ]
  }

  provisioner "shell" {
    script          = "resources/cleanup.sh"
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
  }
}
