#!/usr/bin/env sh

set -eux

OS_VERSION="$1"; shift
ARCHITECTURE="$1"; shift

packer init .

export PACKER_GETTER_READ_TIMEOUT=60m

packer build \
  -var os_version="$OS_VERSION" \
  -var-file "var_files/common.pkrvars.hcl" \
  -var-file "var_files/$ARCHITECTURE.pkrvars.hcl" \
  -var-file "var_files/$OS_VERSION/$ARCHITECTURE.pkrvars.hcl" \
  "$@" \
  freebsd.pkr.hcl
