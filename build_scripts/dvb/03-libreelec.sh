#!/bin/bash

# Set variables
DRIVER_NAME=libreelec
DRIVER_BUILD_DIR=$BUILD_DIR/$DRIVER_NAME
DRIVER_PACKAGE_DIR=$DRIVER_BUILD_DIR/package
DRIVER_OUTPUT_DIR=$WORK_DIR/$KERNEL_V
DRIVER_V_PKG=1.5.0

# Create driver build directory
mkdir $DRIVER_BUILD_DIR
cd $DRIVER_BUILD_DIR

# Make sure that modules are compatible and install them again
make -j$(nproc --all)
make modules_install -j$(nproc --all

# Read necessary configs from file and make sure make oldconfig succeeds
while read -r line
do
  [[ -z "$line" ]] && continue
  line_conf=${line//# /}
  line_conf=${line_conf%%=*}
  line_conf=${line_conf%% *}
  sed -i "/$line_conf/d" "$KERNEL_DIR/.config"
  echo "$line" >> "$KERNEL_DIR/.config"
done < "$WORK_DIR/build_scripts/dvb/libreelec_config"
cd $KERNEL_DIR
yes n | make oldconfig

# Compile modules
make -j$(nproc --all)

# Create directories, install modules
mkdir -p $DRIVER_BUILD_DIR/temp-mods/lib/modules/${KERNEL_V}-mos $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos
cd $KERNEL_DIR
make INSTALL_MOD_PATH=$DRIVER_BUILD_DIR/temp-mods modules_install -j$(nproc --all)

# Compare modules and move only newly comiled modules to modules directory
rsync -rvcm --compare-dest=/lib/modules/${KERNEL_V}-mos/ $DRIVER_BUILD_DIR/temp-mods/lib/modules/${KERNEL_V}-mos/ $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos

# Remove unecessary filese from modules directory
cd $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos
rm $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/* 2>/dev/null
rm -rf $DRIVER_PACKAGE_DIR/lib/modules/${KERNEL_V}-mos/kernel/kernel
find . -depth -exec rmdir {} \;  2>/dev/null

# Create firmware directory and extract firmware files
mkdir -p $DRIVER_PACKAGE_DIR/lib/firmware
tar -C $DRIVER_PACKAGE_DIR/lib/firmware/ -xf $WORK_DIR/build_scripts/dvb/hauppauge_fw_20230602.tar.gz
tar -C $DRIVER_PACKAGE_DIR/lib/firmware/ -xf $WORK_DIR/build_scripts/dvb/libreelec_firmware_${DRIVER_V_PKG}.tar.gz

# Create Debian control file
mkdir $DRIVER_PACKAGE_DIR/DEBIAN
cat > $DRIVER_PACKAGE_DIR/DEBIAN/control << EOF
Package: $DRIVER_NAME
Version: $DRIVER_V_PKG
Architecture: amd64
Maintainer: ich777
Description: LibreELEC drivers for MOS
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
