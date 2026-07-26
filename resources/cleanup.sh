#!/bin/sh

set -exu

cleanup() {
  if command -v pkg > /dev/null 2>&1 && pkg -N > /dev/null 2>&1; then
    pkg clean -a -y
    sed -i '' 's/signature_type: "none"/signature_type: "fingerprints"/' /etc/pkg/FreeBSD.conf
  fi
}

minimize_disk() {
  dd if=/dev/zero of=/EMPTY bs=1M || :
  rm /EMPTY
}

minimize_swap() {
  local swap_device=$(swapctl -l | awk '!/^Device/ { print $1 }')
  if [ -n "$swap_device" ]; then
    swapctl -d "$swap_device"
    dd if=/dev/zero of="$swap_device" bs=1M || :
  fi
}

cleanup
minimize_disk
minimize_swap
