#!/bin/bash

# Set variables
DRIVER_NAME=digital-devices
DRIVER_BUILD_DIR=$BUILD_DIR/$DRIVER_NAME
DRIVER_PACKAGE_DIR=$DRIVER_BUILD_DIR/package
DRIVER_OUTPUT_DIR=$WORK_DIR/$KERNEL_V

# Create driver build directory
mkdir $DRIVER_BUILD_DIR
cd $DRIVER_BUILD_DIR

# Clone from Github, checkout master and get latest commit date
git clone --depth 1 https://github.com/DigitalDevices/dddvb dddvb
cd $DRIVER_BUILD_DIR/dddvb
git checkout master
DRIVER_V_PKG="$(git log -1 --format="%cs" | sed 's/-//g')"

# Build driver and install modules to package dir
make -j$(nproc --all) KDIR=$KERNEL_DIR
make -j$(nproc --all) INSTALL_MOD_PATH=$DRIVER_PACKAGE_DIR KBUILD_EXTMOD=$DRIVER_BUILD_DIR/dddvb modules_install -C $KERNEL_DIR

# Add License
mkdir -p $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME
cat $DRIVER_BUILD_DIR/dddvb/COPYING* >> $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/LICENSE

# Remove unecessary filese from modules directory
cd $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos
rm * 2>/dev/null

# Create Debian control file
mkdir $DRIVER_PACKAGE_DIR/DEBIAN
cat > $DRIVER_PACKAGE_DIR/DEBIAN/control << EOF
Package: $DRIVER_NAME
Version: $DRIVER_V_PKG
Architecture: amd64
Maintainer: ich777
Description: Digital Devices drivers for MOS
EOF

# Create Debian package and md5 checksum
cd $DRIVER_BUILD_DIR
dpkg-deb --build package $DRIVER_OUTPUT_DIR/dvb-${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb

# Check filesize
MIN_SIZE=290000
PACKAGE_SIZE=$(stat -c%s $DRIVER_OUTPUT_DIR/dvb-${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb)
if [ "$PACKAGE_SIZE" -lt "$MIN_SIZE" ] ; then
  echo "ERROR: Package filesize to low, deleting package: dvb-${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb"
  rm -f $DRIVER_OUTPUT_DIR/dvb-${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb
else
  md5sum $DRIVER_OUTPUT_DIR/dvb-${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb | awk '{print $1}' > $DRIVER_OUTPUT_DIR/dvb-${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb.md5
fi
exit 0
