variable "os_version" {
  type = string
  description = "The version of the operating system to download and install"
}

variable "architecture" {
  default = "amd64"
  type = string
  description = "The architecture of CPU to use when building"
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
  image_architecture = var.architecture == "x86-64" ? "amd64" : (
    var.architecture == "arm64" ? "arm64-aarch64" : var.architecture
  )
  vm_name = "freebsd-${var.os_version}-${var.architecture}.qcow2"

  iso_path = "FreeBSD/releases/ISO-IMAGES/${var.os_version}/FreeBSD-${var.os_version}-RELEASE-${local.image_architecture}-disc1.iso"
  iso_target_extension = "iso"
  iso_target_path = "packer_cache"
  iso_full_target_path = "${local.iso_target_path}/${sha1(var.checksum)}.${local.iso_target_extension}"

  /*iso_path = "FreeBSD/releases/ISO-IMAGES/${var.os_version}/FreeBSD-${var.os_version}-RELEASE-${local.image_architecture}-memstick.img"
  iso_target_extension = "img"
  iso_target_path = "packer_cache"
  iso_full_target_path = "${local.iso_target_path}/${sha1(var.checksum)}.${local.iso_target_extension}"*/

  /*iso_path = "FreeBSD/releases/ISO-IMAGES/${var.os_version}/FreeBSD-${var.os_version}-RELEASE-${local.image_architecture}-mini-memstick.img"
  iso_target_extension = "img"
  iso_target_path = "packer_cache"
  iso_full_target_path = "${local.iso_target_path}/${sha1(var.checksum)}.${local.iso_target_extension}"*/

  qemu_architecture = var.architecture == "arm64" ? "aarch64" : (
    var.architecture == "x86-64" ? "x86_64" : var.architecture
  )
}

source "qemu" "qemu" {
  machine_type = var.machine_type
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
  accelerator = var.accelerator
  qemu_binary = "qemu-system-${local.qemu_architecture}"
  firmware = var.firmware

  boot_wait = "10s"

  /*boot_command = [
    "2<enter><wait30s>",
    "<enter><wait5s>",
    "mdmfs -s 100m md1 /tmp<enter><wait>",
    "dhclient -l /tmp/dhclient.leases -p /tmp/dhclient.pid vtnet0<enter><wait5>",
    "fetch -o /tmp/installerconfig http://{{.HTTPIP}}:{{.HTTPPort}}/resources/installerconfig<enter><wait>",
    "ROOT_PASSWORD=${var.root_password} ",
    "OS_VERSION=${var.os_version} ",
    "SECONDARY_USER_USERNAME=${var.secondary_user_username} ",
    "SECONDARY_USER_PASSWORD=${var.secondary_user_password} ",
    "bsdinstall script /tmp/installerconfig && reboot<enter>"
  ]*/

  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout = "10000s"

  qemuargs = [
    ["-cpu", var.cpu_type],
    ["-boot", "strict=off"],
    ["-monitor", "none"],
    ["-device", "virtio-scsi-pci"],
    ["-device", "virtio-blk-device,drive=drive0,bootindex=0"],
    ["-device", "virtio-blk-device,drive=drive1,bootindex=1"],
    ["-drive", "if=none,file={{ .OutputDir }}/{{ .Name }},id=drive0,cache=writeback,discard=ignore,format=qcow2"],
    ["-drive", "if=none,file=${local.iso_full_target_path},id=drive1,media=cdrom,format=raw"],
  ]

  iso_checksum = var.checksum
  iso_target_extension = local.iso_target_extension
  iso_target_path = local.iso_target_path
  iso_urls = [
    "http://ftp.freebsd.org/pub/${local.iso_path}",
    "http://ftp4.se.freebsd.org/pub/${local.iso_path}",
    "http://ftp2.de.freebsd.org/pub/${local.iso_path}",
    "http://ftp.lv.freebsd.org/pub/${local.iso_path}",
    "http://ftp4.us.freebsd.org/pub/${local.iso_path}",
    "http://ftp13.us.freebsd.org/pub/${local.iso_path}",
    "http://ftp6.tw.freebsd.org/pub/${local.iso_path}",
    "http://ftp11.tw.freebsd.org/${local.iso_path}",
    "http://ftp2.br.freebsd.org/${local.iso_path}",
    "http://ftp.at.freebsd.org/pub/${local.iso_path}"
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
      "OS_VERSION=${var.os_version}"
    ]
  }
}
