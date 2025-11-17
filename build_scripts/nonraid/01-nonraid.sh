#!/bin/bash

# Set variables
DRIVER_NAME=nonraid
DRIVER_BUILD_DIR=$BUILD_DIR/$DRIVER_NAME
DRIVER_PACKAGE_DIR=$DRIVER_BUILD_DIR/package
DRIVER_OUTPUT_DIR=$WORK_DIR/$KERNEL_V

# Create driver build directory
mkdir $DRIVER_BUILD_DIR
cd $DRIVER_BUILD_DIR

# Clone from Github, checkout master and get latest commit date
git clone --depth 1 https://github.com/qvr/nonraid $DRIVER_NAME
cd $DRIVER_BUILD_DIR/$DRIVER_NAME
git checkout main
DRIVER_V_PKG="$(git log -1 --format="%cs" | sed 's/-//g')"

# Build driver
cd $DRIVER_BUILD_DIR/$DRIVER_NAME
make -C $KERNEL_DIR M=$DRIVER_BUILD_DIR/$DRIVER_NAME modules CONFIG_UBSAN=n

# Create directory, move modules to package directory and compress modules
mkdir -p $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/kernel/drivers/md $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/kernel/drivers/scsi/raid6
cp $DRIVER_BUILD_DIR/$DRIVER_NAME/md_nonraid/md-nonraid.ko $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/kernel/drivers/md/
cp $DRIVER_BUILD_DIR/$DRIVER_NAME/raid6/nonraid6_pq.ko $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/kernel/drivers/scsi/raid6/
while read -r module
do
  xz --check=crc32 --lzma2 $module
done < <(find $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/kernel -name "*.ko")

# Add License
mkdir -p $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME
cat $DRIVER_BUILD_DIR/$DRIVER_NAME/LICENSE* >> $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/LICENSE

# Create Debian control file
mkdir $DRIVER_PACKAGE_DIR/DEBIAN
cat > $DRIVER_PACKAGE_DIR/DEBIAN/control << EOF
Package: ${DRIVER_NAME}-driver
Version: $DRIVER_V_PKG
Architecture: amd64
Maintainer: ich777
Description: $DRIVER_NAME-driver for MOS
EOF

# Create Debian package and md5 checksum
cd $DRIVER_BUILD_DIR
dpkg-deb --build package $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb

# Check filesize
MIN_SIZE=35000
PACKAGE_SIZE=$(stat -c%s $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb)
if [ "$PACKAGE_SIZE" -lt "$MIN_SIZE" ] ; then
  echo "ERROR: Package filesize to low, deleting package: ${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb"
  rm -f $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb
else
  md5sum $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb | awk '{print $1}' > $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb.md5
fi
exit 0
