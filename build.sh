#!/usr/bin/env sh

set -eux

OS_VERSION="$1"; shift
ARCHITECTURE="$1"; shift

packer init .

export PACKER_GETTER_READ_TIMEOUT=60m

# Download a URL to a local file.  Try curl first (available everywhere),
# then wget as a fallback.
#
# Uses _dl_-prefixed variable names: POSIX sh has no function-local
# variables, so plain names like _out would clobber a caller's variable of
# the same name (fetch_fw_jump relies on its own _out surviving this call).
download() {
  _dl_url="$1"
  _dl_out="$2"
  if curl -fSL -o "$_dl_out" "$_dl_url" 2>/dev/null; then
    return 0
  elif wget -O "$_dl_out" "$_dl_url" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Download and extract OpenSBI fw_jump.bin from the Ubuntu opensbi .deb
# package. Works on macOS and Ubuntu because .deb files are ar archives,
# and tar handles zstd-compressed tarballs on both platforms.
fetch_fw_jump() {
  _out="$1"
  _deb_url="http://archive.ubuntu.com/ubuntu/pool/main/o/opensbi/opensbi_1.4-1_all.deb"
  _workdir="$(dirname "$_out")/opensbi-extract"

  rm -rf "$_workdir"
  mkdir -p "$_workdir"
  download "$_deb_url" "$_workdir/opensbi.deb" || return 1
  (cd "$_workdir" && ar x opensbi.deb)
  bsdtar -xf "$_workdir/data.tar.zst" \
    -C "$_workdir" \
    './usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin'
  mv "$_workdir/usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin" "$_out"
  rm -rf "$_workdir"
}

EXTRA_ARGS=""

# riscv64 uses direct kernel boot via OpenSBI fw_jump.bin (hardcoded to jump
# to 0x80200000, where the FreeBSD kernel expects to be entered). QEMU's
# default fw_dynamic.bin instead jumps to the ELF entry point (a virtual
# address) which hangs before the MMU is set up.
#
# The ISO does not contain the distribution .txz files, so build.sh also
# downloads them and serves them via Packer's HTTP server during install.
if [ "$ARCHITECTURE" = "riscv64" ]; then
  CACHE_DIR=".cache"
  ISO_NAME="FreeBSD-${OS_VERSION}-RELEASE-riscv-riscv64-disc1.iso"
  ISO_PATH="${CACHE_DIR}/${ISO_NAME}"
  KERNEL_PATH="${CACHE_DIR}/kernel"
  FW_JUMP_PATH="${CACHE_DIR}/fw_jump.bin"
  DIST_DIR="resources/dist"
  DIST_BASE_URL="https://ftp.freebsd.org/pub/FreeBSD/releases/riscv/riscv64/${OS_VERSION}-RELEASE"

  mkdir -p "$CACHE_DIR" "$DIST_DIR"

  # Download the ISO if not already cached (Packer also downloads it, but we
  # need a local copy to extract the kernel from).
  if [ ! -f "$ISO_PATH" ]; then
    download "https://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/${OS_VERSION}/${ISO_NAME}" "$ISO_PATH" || \
    download "https://archive.freebsd.org/old-releases/ISO-IMAGES/${OS_VERSION}/${ISO_NAME}" "$ISO_PATH"
  fi

  # Extract the kernel from the ISO (bsdtar/libarchive can read ISO9660)
  if [ ! -f "$KERNEL_PATH" ]; then
    bsdtar -xf "$ISO_PATH" -C "$CACHE_DIR" --include 'boot/kernel/kernel'
    mv "${CACHE_DIR}/boot/kernel/kernel" "$KERNEL_PATH"
    rm -rf "${CACHE_DIR}/boot"
  fi

  # Download fw_jump.bin if not already cached
  if [ ! -f "$FW_JUMP_PATH" ]; then
    fetch_fw_jump "$FW_JUMP_PATH"
  fi

  # Download distribution files for bsdinstall
  for dist_file in MANIFEST kernel.txz base.txz; do
    if [ ! -f "${DIST_DIR}/${dist_file}" ]; then
      download "${DIST_BASE_URL}/${dist_file}" "${DIST_DIR}/${dist_file}"
    fi
  done

  FW_JUMP_ABS="$(cd "$(dirname "$FW_JUMP_PATH")" && pwd)/$(basename "$FW_JUMP_PATH")"
  KERNEL_ABS="$(cd "$(dirname "$KERNEL_PATH")" && pwd)/$(basename "$KERNEL_PATH")"
  ISO_ABS="$(cd "$(dirname "$ISO_PATH")" && pwd)/$(basename "$ISO_PATH")"

  EXTRA_ARGS="-var firmware=$FW_JUMP_ABS -var kernel_path=$KERNEL_ABS -var iso_local_path=$ISO_ABS"
fi

# shellcheck disable=SC2086
packer build \
  -var os_version="$OS_VERSION" \
  -var-file "var_files/common.pkrvars.hcl" \
  -var-file "var_files/$ARCHITECTURE.pkrvars.hcl" \
  -var-file "var_files/$OS_VERSION/$ARCHITECTURE.pkrvars.hcl" \
  $EXTRA_ARGS \
  "$@" \
  freebsd.pkr.hcl
