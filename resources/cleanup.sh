#!/bin/sh

set -exu

cleanup() {
  pkg clean -a -y
  sed -i '' 's/signature_type: "none"/signature_type: "fingerprints"/' /etc/pkg/FreeBSD.conf
}

minimize_disk() {
  dd if=/dev/zero of=/EMPTY bs=1M || :
  rm /EMPTY
}

minimize_swap() {
  local swap_device=$(swapctl -l | awk '!/^Device/ { print $1 }')
  swapctl -d "$swap_device"
  dd if=/dev/zero of="$swap_device" bs=1M || :
}

cleanup
minimize_disk
minimize_swap
