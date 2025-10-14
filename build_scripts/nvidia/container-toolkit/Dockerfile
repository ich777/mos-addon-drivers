FROM debian:buster-slim

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends dpkg wget curl ca-certificates \
  git build-essential dh-make fakeroot devscripts lsb-release && \
  rm -rf /var/lib/apt/lists/*

ENV OS_ARCH="amd64"
ENV GOLANG_VERSION="1.22.12"
ENV BUILD_DIR=/tmp
ENV GOPATH=$BUILD_DIR/go
ENV PATH=/opt/go/bin:$PATH
ENV GPG_TTY=/dev/console
ENV PACKAGE_DIR=$BUILD_DIR/package

COPY config.toml /opt/config.toml

RUN curl https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-${OS_ARCH}.tar.gz | tar -C /opt -xz
RUN chmod -R 777 /opt

CMD bash -c "cd ${BUILD_DIR} && \
  mkdir -p ${BUILD_DIR}/go/src/github.com/NVIDIA && \
  cd ${BUILD_DIR}/go/src/github.com/NVIDIA && \
  git clone --depth 1 --branch v${TOOLKIT_VERSION} https://github.com/NVIDIA/nvidia-container-toolkit && \
  cd ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit && \
  git checkout v${TOOLKIT_VERSION} && \
  mkdir -p $PACKAGE_DIR/usr/bin $PACKAGE_DIR/DEBIAN $PACKAGE_DIR/etc/nvidia-container-runtime && \
  make LIBNVIDIA_CONTAINER_VERSION=${TOOLKIT_VERSION} LIBNVIDIA_CONTAINER_TAG=${TOOLKIT_VERSION} binaries && \
  cp ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-container-runtime-hook $PACKAGE_DIR/usr/bin && \
  cp ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-container-runtime $PACKAGE_DIR/usr/bin && \
  cp ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-ctk $PACKAGE_DIR/usr/bin && \
  cp ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-cdi-hook $PACKAGE_DIR/usr/bin && \
  cp ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-container-runtime.cdi $PACKAGE_DIR/usr/bin && \
  cp ${BUILD_DIR}/go/src/github.com/NVIDIA/nvidia-container-toolkit/nvidia-container-runtime.legacy $PACKAGE_DIR/usr/bin && \
  cd $PACKAGE_DIR/usr/bin && \
  ln -s /usr/bin/nvidia-container-runtime-hook /usr/bin/nvidia-container-toolkit && \
  cp /opt/config.toml $PACKAGE_DIR/etc/nvidia-container-runtime/config.toml && \
  cat $DRIVER_BUILD_DIR/$DRIVER_NAME/LICENSE* >> $PACKAGE_DIR/etc/nvidia-container-runtime/LICENSE && \
  cd ${BUILD_DIR}/nvidia-container-toolkit-${TOOLKIT_VERSION} && \
  cat > $PACKAGE_DIR/DEBIAN/control << 'EOF'
Package: nvidia-container-toolkit
Version: $TOOLKIT_VERSION
Architecture: amd64
Maintainer: ich777
Description: nvidia-container-toolkit for MOS
EOF && \
  cd ${BUILD_DIR} && \
  dpkg-deb --build package $BUILD_DIR/nvidia-container-toolkit_${TOOLKIT_VERSION}-1+mos_amd64.deb && \
  md5sum $BUILD_DIR/nvidia-container-toolkit_${TOOLKIT_VERSION}-1+mos_amd64.deb | awk '{print $1}' > $BUILD_DIR/nvidia-container-toolkit_${TOOLKIT_VERSION}-1+mos_amd64.deb.md5"
