#!/bin/bash

# Set variables
DRIVER_NAME=coral
DRIVER_BUILD_DIR=$BUILD_DIR/$DRIVER_NAME
DRIVER_PACKAGE_DIR=$DRIVER_BUILD_DIR/package
DRIVER_OUTPUT_DIR=$WORK_DIR/$KERNEL_V

# Create driver build directory
mkdir $DRIVER_BUILD_DIR
cd $DRIVER_BUILD_DIR

# Clone from Github, checkout master and get latest commit date
git clone --depth 1 https://github.com/google/gasket-driver $DRIVER_NAME
cd $DRIVER_BUILD_DIR/$DRIVER_NAME
git checkout master
DRIVER_V_PKG="$(git log -1 --format="%cs" | sed 's/-//g')"

# Patch for 6.13+
patch -p1 < $BUILD_DIR/$DRIVER_NAME/coral_6.13.0.patch

# Build driver
cd $DRIVER_BUILD_DIR/$DRIVER_NAME/src
make -j$(nproc --all) KDIR=$KERNEL_DIR

# Create directory, move modules to package directory and compress modules
mkdir -p $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/extra
cp $DRIVER_BUILD_DIR/$DRIVER_NAME/src/*.ko $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/extra/
while read -r module
do
  xz --check=crc32 --lzma2 $module
done < <(find $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/extra -name "*.ko")

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
Description: Coral Gasket drivers for MOS
EOF

# Create Debian package and md5 checksum
cd $DRIVER_BUILD_DIR
dpkg-deb --build package $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb
md5sum $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb | awk '{print $1}' > $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb.md5
exit 0
