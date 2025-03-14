#!/bin/sh

# Environment variables:
# OS_VERSION: the version of FreeBSD
# SECONDARY_USER_USERNAME: the username of the secondary user to create
# SECONDARY_USER_PASSWORD: the password of the secondary
# PKG_SITE_ARCHITECTURE: the name of the architecture used by the pkg site: http://pkg.freebsd.org

set -exu

ABI_VERSION="$(echo $OS_VERSION | cut -d . -f 1)"

configure_boot_flags() {
  cat <<EOF >> /boot/loader.conf
autoboot_delay="-1"
console="comconsole"
EOF
}

configure_sendmail() {
  tee -a /etc/rc.conf <<EOF
sendmail_enable="NO"
sendmail_submit_enable="NO"
sendmail_outbound_enable="NO"
sendmail_msp_queue_enable="NO"
EOF
}

configure_boot_scripts() {
  local rc_dir=/usr/local/etc/rc.d
  local script="$rc_dir/install_authorized_keys.sh"

  mkdir -p "$rc_dir"

  cat <<EOF >> "$script"
#!/usr/local/bin/bash

RESOURCES_MOUNT_PATH='/mnt/resources'

is_mounted() {
  local disk="\$1"

  return \$(
    echo "\$mounts" | while read mount; do
      [[ "\$mount" == "/dev/\$disk"* ]] && return 0
      return 1
    done
  )
}

mount_resources_disk() {
  local disks=\$(sysctl kern.disks | cut -d : -f 2 | sed 's/ /\n/g' | tail -n +2)
  local mounts=\$(mount)

  echo "\$disks" | while read disk; do
    is_mounted "\$disk" && continue

    find /dev -name "\$disk*" | while read dev; do
      [ "\$dev" = "/dev/\$disk" ] && continue
      mkdir -p /mnt/resources
      mount_msdosfs "\$dev" /mnt/resources
      break
    done
  done
}

install_authorized_keys() {
  if [ -s "\$RESOURCES_MOUNT_PATH/KEYS" ]; then
    mkdir -p "/home/$SECONDARY_USER_USERNAME/.ssh"
    cp "\$RESOURCES_MOUNT_PATH/keys" "/home/$SECONDARY_USER_USERNAME/.ssh/authorized_keys"
    chown "$SECONDARY_USER_USERNAME:$SECONDARY_USER_USERNAME" "/home/$SECONDARY_USER_USERNAME/.ssh/authorized_keys"
    chmod 600 "/home/$SECONDARY_USER_USERNAME/.ssh/authorized_keys"
  fi
}

mount_resources_disk
install_authorized_keys
EOF

  chmod +x "$script"
}

upstream_pkg_site_available() {
  if [ "$OS_VERSION" = "13.0" ]; then
    upstream_package_available "pkg.txz"
    return
  fi

  upstream_package_available "pkg.pkg" || upstream_package_available "pkg.txz"
}

upstream_package_available() {
  local package_name="$1"
  local package_site="http://pkg.FreeBSD.org/FreeBSD:$ABI_VERSION:$PKG_SITE_ARCHITECTURE/quarterly/Latest"

  fetch \
    --print-size \
    "$package_site/$package_name" \
    "$package_site/$package_name.sig" \
    > /dev/null 2>&1
}

bootstrap_pkg() {
  local device_version="$(echo "$OS_VERSION" | sed 's/\./_/')"
  local device_arch="$(echo "$PKG_SITE_ARCHITECTURE" | tr '[:lower:]' '[:upper:]')"

  if [ -e /dev/cd0 ]; then
    local device_path=/dev/cd0
  elif [ -e "/dev/iso9660/${device_version}_RELEASE_${device_arch}_DVD" ]; then
    local device_path="/dev/iso9660/${device_version}_RELEASE_${device_arch}_DVD"
  else
    echo "ERROR: There is no DVD/CDROM device available to mount" >&2
    exit 1
  fi

  sed -i '' 's/signature_type: "fingerprints"/signature_type: "none"/' /etc/pkg/FreeBSD.conf
  mount -t cd9660 "$device_path" /mnt
  export PACKAGESITE="file:///mnt/packages/FreeBSD:$ABI_VERSION:$PKG_SITE_ARCHITECTURE"
  ASSUME_ALWAYS_YES=yes pkg bootstrap
}

install_local_package() {
  ASSUME_ALWAYS_YES=yes pkg add "/mnt/packages/FreeBSD:$ABI_VERSION:$PKG_SITE_ARCHITECTURE/All/$1"-[0123456789]*
}

install_extra_packages() {
  if upstream_pkg_site_available; then
    ASSUME_ALWAYS_YES=yes pkg install sudo bash curl rsync
  else
    bootstrap_pkg
    install_local_package sudo
    install_local_package bash
    install_local_package curl
    install_local_package rsync
  fi
}

configure_sudo() {
  mkdir -p /usr/local/etc/sudoers.d
  cat <<EOF > "/usr/local/etc/sudoers.d/$SECONDARY_USER_USERNAME"
Defaults:$SECONDARY_USER_USERNAME !requiretty
$SECONDARY_USER_USERNAME ALL=(ALL) NOPASSWD: ALL
EOF
  chmod 440 "/usr/local/etc/sudoers.d/$SECONDARY_USER_USERNAME"
}

setup_secondary_user() {
  echo "$SECONDARY_USER_PASSWORD" | pw useradd "$SECONDARY_USER_USERNAME" -h 0 -m -s "$SHELL"
}

setup_secondary_user
configure_boot_flags
configure_sendmail
configure_boot_scripts
install_extra_packages
configure_sudo
