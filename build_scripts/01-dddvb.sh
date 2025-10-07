#!/bin/bash

# Set variables
DRIVER_NAME=digtial-devices
DRIVER_BUILD_DIR=$BUILD_DIR/$DRIVER_NAME
DRIVER_PACKAGE_DIR=$DRIVER_BUILD_DIR/package

# Create driver build directory
mkdir $DRIVER_BUILD_DIR
cd $DRIVER_BUILD_DIR

# Clone from Github, checkout master and get latest commit date
git clone --depth 1 https://github.com/DigitalDevices/dddvb dddvb
cd $DRIVER_BUILD_DIR/dddvb
git checkout master
DD_DRV_V="$(git log -1 --format="%cs" | sed 's/-//g')"

# Build driver and install modules to package dir
make -j$(nproc --all) KDIR=$KERNEL_DIR
make -j$(nproc --all) INSTALL_MOD_PATH=$DRIVER_PACKAGE_DIR KBUILD_EXTMOD=$DRIVER_BUILD_DIR/dddvb modules_install -C $KERNEL_DIR

# Add License
mkdir -p $DRIVER_PACKAGE_DIR/usr/share/doc/digital-devices
cat $DRIVER_BUILD_DIR/dddvb/COPYING* >> $DRIVER_PACKAGE_DIR/usr/share/doc/digital-devices/LICENSE

# Remove unecessary filese from modules directory
cd $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos
rm * 2>/dev/null

# Create Debian control file
mkdir $DRIVER_PACKAGE_DIR/DEBIAN
cat > $DRIVER_PACKAGE_DIR/DEBIAN/control << EOF
Package: digital-devices
Version: $DD_DRV_V
Architecture: amd64
Maintainer: ich777
Description: Digital Devices drivers for MOS
EOF

# Create Debian package and md5 checksum
cd $DRIVER_BUILD_DIR
dpkg-deb --build package $WORK_DIR/$KERNEL_V/dvb-digital-devices_${DD_DRV_V}-1+mos_amd64.deb
md5sum $WORK_DIR/$KERNEL_V/dvb-digital-devices_${DD_DRV_V}-1+mos_amd64.deb | awk '{print $1}' > $WORK_DIR/$KERNEL_V/dvb-digital-devices_${DD_DRV_V}-1+mos_amd64.deb.md5
exit 0
