#!/bin/sh

# Environment variables:
# OS_VERSION: the version of FreeBSD
# SECONDARY_USER_USERNAME: the username of the secondary user to create
# PKG_SITE_ARCHITECTURE: the name of the architecture used by the pkg site: http://pkg.freebsd.org

set -exu

ABI_VERSION="$(echo $OS_VERSION | cut -d . -f 1)"
PACKAGE_SITE="https://pkg.FreeBSD.org/FreeBSD:$ABI_VERSION:$PKG_SITE_ARCHITECTURE/quarterly/Latest"
IGNORE_OSVERSION=yes
ASSUME_ALWAYS_YES=yes

export IGNORE_OSVERSION
export ASSUME_ALWAYS_YES

configure_boot_flags() {
  cat <<EOF >> /boot/loader.conf
autoboot_delay="-1"
console="comconsole"
EOF
}

configure_sendmail() {
  sysrc sendmail_enable=NO
  sysrc sendmail_submit_enable=NO
  sysrc sendmail_outbound_enable=NO
  sysrc sendmail_msp_queue_enable=NO
}

upstream_pkg_site_available() {
  if [ "$OS_VERSION" = "13.0" ]; then
    if upstream_package_available "pkg.txz"; then
      return 0
    elif upstream_package_available "pkg.pkg"; then
      bootstrap_pkg_remote
      return 0
    else
      return 1
    fi
  fi

  upstream_package_available "pkg.pkg" || upstream_package_available "pkg.txz"
}

upstream_package_available() {
  local package_name="$1"

  fetch \
    --print-size \
    "$PACKAGE_SITE/$package_name" \
    "$PACKAGE_SITE/$package_name.sig" \
    > /dev/null 2>&1
}

bootstrap_pkg_remote() {
  pushd /tmp > /dev/null
  fetch "$PACKAGE_SITE/pkg.pkg" "$PACKAGE_SITE/pkg.pkg.sig"
  pkg add pkg.pkg
  rm -f pkg.pkg pkg.pkg.sig
  popd > /dev/null
}

bootstrap_pkg_install_media() {
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
  pkg bootstrap
}

install_local_package() {
  pkg add "/mnt/packages/FreeBSD:$ABI_VERSION:$PKG_SITE_ARCHITECTURE/All/$1"-[0123456789]*
}

install_extra_packages() {
  if upstream_pkg_site_available; then
    pkg install sudo bash curl rsync
  else
    bootstrap_pkg_install_media
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
  pw useradd "$SECONDARY_USER_USERNAME" -m -s "$SHELL" -w none
}

setup_secondary_user
configure_boot_flags
configure_sendmail
install_extra_packages
configure_sudo
