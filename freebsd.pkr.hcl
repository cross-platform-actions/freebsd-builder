packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "os_version" {
  type = string
  description = "The version of the operating system to download and install"
}

variable "architecture" {
  default = "amd64"
  type = string
  description = "The architecture of CPU to use when building"
}

variable "image_architecture" {
  default = "amd64"
  type = string
  description = "The name of the architecture used by the ISO image"
}

variable "qemu_architecture" {
  default = "x86_64"
  type = string
  description = "The name of the architecture in the QEMU binary"
}

variable "pkg_site_architecture" {
  type = string
  description = "The name of the architecture used by the pkg site: http://pkg.freebsd.org"
}

variable "machine_type" {
  default = "pc"
  type = string
  description = "The type of machine to use when building"
}

variable "cpu_type" {
  default = "qemu64"
  type = string
  description = "The type of CPU to use when building"
}

variable "memory" {
  default = 4096
  type = number
  description = "The amount of memory to use when building the VM in megabytes"
}

variable "cpus" {
  default = 2
  type = number
  description = "The number of cpus to use when building the VM"
}

variable "disk_size" {
  default = "12G"
  type = string
  description = "The size in bytes of the hard disk of the VM"
}

variable "checksum" {
  type = string
  description = "The checksum for the virtual hard drive file"
}

variable "root_password" {
  default = "vagrant"
  type = string
  description = "The password for the root user"
}

variable "secondary_user_password" {
  default = "vagrant"
  type = string
  description = "The password for the `secondary_user_username` user"
}

variable "secondary_user_username" {
  default = "vagrant"
  type = string
  description = "The name for the secondary user"
}

variable "headless" {
  default = false
  description = "When this value is set to `true`, the machine will start without a console"
}

variable "use_default_display" {
  default = true
  type = bool
  description = "If true, do not pass a -display option to qemu, allowing it to choose the default"
}

variable "display" {
  default = "cocoa"
  description = "What QEMU -display option to use"
}

variable "accelerator" {
  default = "tcg"
  type = string
  description = "The accelerator type to use when running the VM"
}

variable "firmware" {
  type = string
  description = "The firmware file to be used by QEMU"
}

locals {
  vm_name = "freebsd-${var.os_version}-${var.architecture}.qcow2"
  iso_path = "ISO-IMAGES/${var.os_version}/FreeBSD-${var.os_version}-RELEASE-${var.image_architecture}-dvd1.iso"
}

source "qemu" "qemu" {
  machine_type = "${var.machine_type}"
  cpus = var.cpus
  memory = var.memory
  net_device = "virtio-net"

  disk_compression = true
  disk_interface = "virtio"
  disk_size = var.disk_size
  format = "qcow2"

  headless = var.headless
  use_default_display = var.use_default_display
  display = var.display
  accelerator = "none" // we manually specify multiple accelerators below
  qemu_binary = "qemu-system-${var.qemu_architecture}"
  firmware = var.firmware

  boot_wait = "6s"

  boot_command = [
    "2<wait30s>",
    "<enter><wait10>",
    "mdmfs -s 100m md1 /tmp<enter><wait>",
    "dhclient -l /tmp/dhclient.leases -p /tmp/dhclient.pid vtnet0<enter><wait5>",
    "fetch -o /tmp/installerconfig http://{{.HTTPIP}}:{{.HTTPPort}}/resources/installerconfig<enter><wait>",
    "ROOT_PASSWORD=${var.root_password} ",
    "bsdinstall script /tmp/installerconfig && reboot<enter>"
  ]

  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout = "10000s"

  qemuargs = [
    ["-cpu", var.cpu_type],
    ["-boot", "strict=off"],
    ["-monitor", "none"],
    ["-accel", "hvf"],
    ["-accel", "kvm"],
    ["-accel", "tcg"]
  ]

  iso_checksum = var.checksum
  iso_urls = [
    "http://ftp.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/${local.iso_path}",
    "http://ftp4.se.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp2.de.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp.lv.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp4.us.freebsd.org/pub/FreeBSD/releases/${local.iso_path}",
    "http://ftp.at.freebsd.org/pub/FreeBSD/releases/${local.iso_path}"
  ]

  http_directory = "."
  output_directory = "output"
  shutdown_command = "shutdown -p now"
  vm_name = local.vm_name
}

build {
  sources = ["qemu.qemu"]

  provisioner "shell" {
    script = "resources/provision.sh"
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "SECONDARY_USER_USERNAME=${var.secondary_user_username}",
      "SECONDARY_USER_PASSWORD=${var.secondary_user_password}",
      "OS_VERSION=${var.os_version}",
      "PKG_SITE_ARCHITECTURE=${var.pkg_site_architecture}"
    ]
  }

  provisioner "shell" {
    script = "resources/custom.sh"
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
    environment_vars = [
      "SECONDARY_USER_USERNAME=${var.secondary_user_username}"
    ]
  }

  provisioner "shell" {
    script = "resources/cleanup.sh"
    execute_command = "chmod +x {{ .Path }}; env {{ .Vars }} {{ .Path }}"
  }
}
