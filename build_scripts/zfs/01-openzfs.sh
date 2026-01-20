#!/bin/bash

# Set variables
DRIVER_NAME=openzfs
DRIVER_BUILD_DIR=$BUILD_DIR/$DRIVER_NAME
DRIVER_PACKAGE_DIR=$DRIVER_BUILD_DIR/package
DRIVER_OUTPUT_DIR=$WORK_DIR/$KERNEL_V

# Create driver build directory
mkdir $DRIVER_BUILD_DIR
cd $DRIVER_BUILD_DIR

# Get latest ZFS version:
DRIVER_V_PKG="$(curl -s https://api.github.com/repos/openzfs/zfs/tags | jq -r '[.[] | select(.name | test("-(rc|beta|alpha)|\\.99"; "i") | not)] | .[].name' | cut -d '-' -f2 | sort -V | tail -1)"

# Download source and create directory
wget -q -O $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}.tar.gz https://github.com/openzfs/zfs/archive/refs/tags/zfs-${DRIVER_V_PKG}.tar.gz
mkdir -p $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}
tar -C $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG} --strip-components=1 -xf $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}.tar.gz
cd $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}

# Execute autogen if necessary
if [ ! -f $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/configure ]; then
  $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/autogen.sh
fi

# Configure and build driver
$DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/configure --prefix=/usr --libdir=/lib/x86_64-linux-gnu --sysconfdir=/etc
make -j$(nproc --all)

# Install files to package directory
DESTDIR=$DRIVER_PACKAGE_DIR make install -j${CPU_COUNT}

# Strip header and other not strictly necessary directories/files
rm -rf $DRIVER_PACKAGE_DIR/usr/include $DRIVER_PACKAGE_DIR/usr/src $DRIVER_PACKAGE_DIR/etc/sudoers.d $DRIVER_PACKAGE_DIR/lib/x86_64-linux-gnu/pkgconfig
find $DRIVER_PACKAGE_DIR/lib/x86_64-linux-gnu -type f \( -name "*.a" -o -name "*.la" \) -delete

# Add License files
mkdir -p $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME
cp $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/LICENSE $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/LICENSE
cp $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/COPYRIGHT $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/COPYRIGHT
cp $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/NOTICE $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/NOTICE
cp $DRIVER_BUILD_DIR/zfs-${DRIVER_V_PKG}/AUTHORS $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/AUTHORS
echo "OpenZFS source code is available at:
https://github.com/openzfs/zfs

Built from:
OpenZFS version: $DRIVER_V_PKG" >> $DRIVER_PACKAGE_DIR/usr/share/doc/$DRIVER_NAME/source.txt


# Create Debian control file
mkdir $DRIVER_PACKAGE_DIR/DEBIAN
cat > $DRIVER_PACKAGE_DIR/DEBIAN/control << EOF
Package: $DRIVER_NAME
Version: $DRIVER_V_PKG
Architecture: amd64
Maintainer: ich777
Description: $DRIVER_NAME driver for MOS
EOF

# Create Debian package and md5 checksum
cd $DRIVER_BUILD_DIR
dpkg-deb --build package $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb

# Check filesize
MIN_SIZE=28000000
PACKAGE_SIZE=$(stat -c%s $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb)
if [ "$PACKAGE_SIZE" -lt "$MIN_SIZE" ] ; then
  echo "ERROR: Package filesize to low, deleting package: ${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb"
  rm -f $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb
else
  md5sum $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb | awk '{print $1}' > $DRIVER_OUTPUT_DIR/${DRIVER_NAME}_${DRIVER_V_PKG}-1+mos_amd64.deb.md5
fi
exit 0
