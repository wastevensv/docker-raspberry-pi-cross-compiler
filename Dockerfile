FROM debian:stretch

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        automake \
        cmake \
        curl \
        fakeroot \
        g++ \
        git \
        make \
        runit \
        sudo \
        xz-utils

# Here is where we hardcode the toolchain decision.
ENV HOST=arm-linux-gnueabihf \
    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \
    RPXC_ROOT=/rpxc

#    TOOLCHAIN=arm-rpi-4.9.3-linux-gnueabihf \
#    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \

WORKDIR $RPXC_ROOT
RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/"

ENV ARCH=arm \
    CROSS_COMPILE=$RPXC_ROOT/bin/$HOST- \
    PATH=$RPXC_ROOT/bin:$PATH \
    QEMU_PATH=/usr/bin/qemu-arm-static \
    QEMU_EXECVE=1 \
    SYSROOT=$RPXC_ROOT/sysroot

WORKDIR $SYSROOT
ADD raspbian.2018.03.13.tar.xz $SYSROOT
ADD qemu-arm-static $QEMU_PATH
RUN chmod +x $QEMU_PATH

RUN mkdir -p $SYSROOT/build \
 && chroot $SYSROOT $QEMU_PATH /bin/bash -l -c '\
        echo "deb http://archive.raspbian.org/raspbian stretch firmware" \
            >> /etc/apt/sources.list \
        && mknod -m 622 /dev/console c 5 1 \
        && mknod -m 666 /dev/null c 1 3    \
        && mknod -m 666 /dev/zero c 1 5    \
        && mknod -m 666 /dev/ptmx c 5 2    \
        && mknod -m 666 /dev/tty c 5 0     \
        && mknod -m 444 /dev/random c 1 8  \
        && mknod -m 444 /dev/urandom c 1 9 \
        && apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
        && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
        && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libc6-dev \
                symlinks \
        && symlinks -cors /'

COPY image/ /

WORKDIR /build
ENTRYPOINT [ "/rpxc/entrypoint.sh" ]

RUN install-debian libc6-armhf-cross
