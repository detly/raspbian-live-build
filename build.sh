#!/bin/sh
lb config \
    --apt-indices none \
    --apt-source-archives false \
    --distribution wheezy \
    --binary-images hdd \
    --hdd-size 512 \
    --architectures armhf \
    --bootstrap-qemu-arch armhf \
    --bootstrap-qemu-static /usr/bin/qemu-arm-static \
    --firmware-binary false \
    --firmware-chroot false

sudo lb build
