#!/bin/sh

set -exu

configure_boot_flags() {
  cat <<EOF >> /boot/loader.conf
autoboot_delay="-1"
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

install_extra_packages() {
  ASSUME_ALWAYS_YES=yes pkg install sudo bash curl rsync
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

cleanup() {
  pkg clean -a -y
}

minimize_disk() {
  dd if=/dev/zero of=/EMPTY bs=1M || :
  rm /EMPTY
}

minimize_swap() {
  swap_device=$(swapctl -l | awk '!/^Device/ { print $1 }')
  swapctl -d "$swap_device"
  dd if=/dev/zero of="$swap_device" bs=1M || :
}

setup_secondary_user
configure_boot_flags
configure_sendmail
configure_boot_scripts
install_extra_packages
configure_sudo

cleanup
minimize_disk
minimize_swap
