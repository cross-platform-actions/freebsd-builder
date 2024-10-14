#!/bin/sh

set -exu

# Add your additional provisioning here for custom VM images.

ASSUME_ALWAYS_YES=yes pkg install poudriere-devel tree git

TMPFS_BLACKLIST="rust rust-*"
ALLOW_MAKE_JOBS_PACKAGES="rust-*"

# create poudriere.conf
DISTFILES_CACHE=/usr/ports/distfiles
CONFIG_FILE=/usr/local/etc/poudriere.conf
rm -f "${CONFIG_FILE}"
touch "${CONFIG_FILE}"

echo NO_ZFS=yes >> ${CONFIG_FILE}
echo FREEBSD_HOST=https://download.FreeBSD.org >> ${CONFIG_FILE}
echo RESOLV_CONF=/etc/resolv.conf >> ${CONFIG_FILE}
echo BASEFS=/usr/local/poudriere >> ${CONFIG_FILE}
echo USE_PORTLINT=no >> ${CONFIG_FILE}
echo USE_TMPFS=yes >> ${CONFIG_FILE}
echo TMPFS_BLACKLIST=\"${TMPFS_BLACKLIST}\" >> ${CONFIG_FILE}
echo TMPFS_BLACKLIST_TMPDIR=\${BASEFS}/data/cache/tmp >> ${CONFIG_FILE}
echo DISTFILES_CACHE=${DISTFILES_CACHE} >> ${CONFIG_FILE}
echo CCACHE_DIR=/var/cache/ccache >> ${CONFIG_FILE}
echo PACKAGE_FETCH_URL=pkg+http://pkg.FreeBSD.org/\\\${ABI} >> ${CONFIG_FILE}
echo ALLOW_MAKE_JOBS_PACKAGES=\"${ALLOW_MAKE_JOBS_PACKAGES}\" >> ${CONFIG_FILE}

# build all FLAVORS by default
echo FLAVOR_DEFAULT_ALL=yes >> ${CONFIG_FILE}
cat "${CONFIG_FILE}"

# create the ports tree
PORTS_URL="https://github.com/freebsd/freebsd-ports.git"
poudriere ports -c -p default -B main -U "${PORTS_URL}"
poudriere ports -l

# create a symlink to the ports tree
ln -s /usr/local/poudriere/ports/default /usr/ports

# create a jail
JAIL_NAME_VERSION=`uname -r | sed -E -e 's/-(CURRENT|RELEASE).*//' -e 's/\.//'`
JAIL_NAME_ARCH=`uname -m`
JAIL_NAME="${JAIL_NAME_VERSION}${JAIL_NAME_ARCH}"
JAIL_VERSION=`uname -r | sed -E -e 's/-p[0-9]+$//'`
poudriere jail -c -j "${JAIL_NAME}" -v "${JAIL_VERSION}"
poudriere jail -l

# create required directories
mkdir -p "${DISTFILES_CACHE}"

df -h
