#!/bin/bash


. /ci-scripts/include.sh

arch=`dpkg-architecture -q DEB_BUILD_ARCH`

#  ${PRODUCT}           set by gitlab-ci
#  ${DEBIAN_VERSION}    from bob-the-builder image
#  ${arch}              from building arch

PROJECT_VERSION=$(dpkg-parsechangelog -S Version)

if [ -z "${PRODUCT}" ]; then
    ################## dkms #################333
    BINARY_PKG_NAME=unipi-kernel-modules-dkms
    unset pre_depends
    depends="raspberrypi-kernel-headers | unipi-kernel-headers | linux-headers-rpi-v8 | linux-headers-rpi-2712, unipi-os-configurator-data"
    unset suggests
    cat >debian/rules.in <<EOF
%:
	dh \$@  --with dkms

override_dh_prep:
	@dh_prep --exclude=${BINARY_PKG_NAME}.substvars
	@echo unipi:Pre-Depends="${pre_depends}" >> debian/${BINARY_PKG_NAME}.substvars
	@echo unipi:Depends="${depends}" >> debian/${BINARY_PKG_NAME}.substvars
	@echo unipi:Suggests="${suggests}" >> debian/${BINARY_PKG_NAME}.substvars

override_dh_dkms:
	dh_dkms -V ${PROJECT_VERSION}
	make dkms DESTDIR=${PWD}/debian/unipi-kernel-modules-dkms/usr/src/unipi-${PROJECT_VERSION}
	sed '/# insert modules here #/r dkms.conf' \
	    -i ${PWD}/debian/unipi-kernel-modules-dkms/usr/src/unipi-${PROJECT_VERSION}/dkms.conf

override_dh_auto_build:

override_dh_auto_install:

EOF
    exit 0
    ################## end of dkms #################333
fi

#RPI_CONFLICT="linux-base-rpi-v8, linux-base-rpi-2712, linux-baserpi-v8-rt, linux-base-rpi-v8-rt"
BINARY_PKG_NAME=unipi-kernel-modules
case "${PRODUCT}" in
    edge | zulu)
        PKG_KERNEL_HEADERS=unipi-kernel-headers
        PKG_KERNEL_IMAGE=unipi-kernel
        ;;
    * )
        echo "Unsupported platform" >&2
        exit 1
        ;;
esac

PKG_KERNEL_VER="$(dpkg-query -f='${Version}\n' -W ${PKG_KERNEL_HEADERS} | sed -n '1p')"
echo "PKG_KERNEL_VER = ${PKG_KERNEL_VER}"
# strip the first ":" part (epoch)
PKG_KERNEL_VER_STRIPPED="$(echo ${PKG_KERNEL_VER} | cut -d":" -f 2-)"
echo "PKG_KERNEL_VER_STRIPPED = ${PKG_KERNEL_VER_STRIPPED}"

LINUX_DIR_PATH=$(dpkg -L ${PKG_KERNEL_HEADERS} | sed -n '/^\/lib\/modules\/.*\/build$/p')

#####################################################################
### Create changelog for binary packages with modified version string

MODULES_VERSION=${PROJECT_VERSION}~${PKG_KERNEL_VER_STRIPPED}
cat  >debian/${BINARY_PKG_NAME}.changelog <<EOF
unipi-kernel-modules (${MODULES_VERSION}) unstable; urgency=medium
  * Compiled for ${PKG_KERNEL_IMAGE}
 -- auto-generator <info@unipi.technology>  $(date -R)

EOF
cat debian/changelog >>debian/${BINARY_PKG_NAME}.changelog

#####################################################################
### Append binary packages definition to control file

depends="unipi-os-configurator-data"

cat >>debian/control <<EOF

Package: ${BINARY_PKG_NAME}
Architecture: ${arch}
Depends: ${misc:Depends}, ${PKG_KERNEL_IMAGE}(=${PKG_KERNEL_VER}), ${depends}
Description: Unipi kernel modules
 Binary kernel modules for Unipi controllers.
 Compiled for ${PKG_KERNEL_IMAGE} version ${PKG_KERNEL_VER}.

EOF

#####################################################################
### Create rules.in

cat  >debian/rules.in <<EOF

%:
	dh \$@

override_dh_auto_install:
	mkdir -p debian/${BINARY_PKG_NAME}
	mv debian/tempdest/* debian/${BINARY_PKG_NAME}

override_dh_auto_build:
	make clean
	dh_auto_build -- LINUX_DIR_PATH=${LINUX_DIR_PATH}
	dh_auto_install --destdir=debian/tempdest -- LINUX_DIR_PATH=${LINUX_DIR_PATH}
EOF

echo "==============================================================================================================="
echo "debian/rules"
echo "==============================================================================================================="
cat debian/rules.in

echo "==============================================================================================================="
echo "debian/control"
echo "==============================================================================================================="
cat debian/control


