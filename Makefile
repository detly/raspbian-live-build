#!/bin/sh

BUILD_LOG := build.log

# --apt-indices none :  Reduce image size by not including apt indicies
# --apt-secure false :  Don't bother checking repository signatures
# --apt-source-archives false  : Don't include source-code repository
# --archive-areas 'main firmware non-free' : Which APT repo areas to include
# --bootappend-live "..." : kernel command-line
# --bootstrap-flavour minimal : build a minimal Debian system
# --cache-stages false : Don't cache output of build stages, so rebuilds start clean
GENERAL_BUILD_OPTIONS = \
	--apt-indices none \
	--apt-secure false \
	--apt-source-archives false \
	--archive-areas 'main firmware non-free' \
	--bootappend-live "boot=live config hostname=pi username=pi" \
	--cache-stages false \
	--compression gzip \
	--distribution jessie \
	--gzip-options '-9 --rsyncable' \
	--mode debian \
	--security false

# --binary-filesystem fat32
# --binary-images hdd : Build an HDD image
# --chroot-filesystem squashfs : Build the rootfs as a squashfs image file
# --hdd-size 512 : Build a 512MB filesystem
# --initramfs live-boot : Build a debian "live-boot" initrd that bootstraps the squashfs rootfs
# --system live : Build a "live" system (i.e. squashfs with aufs overlay)
HDD_IMAGE_BUILD_OPTIONS = \
	--binary-filesystem fat32 \
	--binary-images hdd \
	--chroot-filesystem squashfs \
	--hdd-size 512 \
	--initramfs live-boot \
	--system live

# --architectures armhf : target armhf processor
# --bootstrap-qemu-arch armhf
# --bootstrap-qemu-static /usr/bin/qemu-arm-static
# --firmware-binary false : Don't include i386/amd64 firmware/drivers
# --firmware-chroot false : Don't include i386/amd64 firmware/drivers
# --linux-flavours rpi : Install the RaspberryPi-optimised linux kernel
# --mirror-bootstrap/binary etc :  Use the Raspbian apt repository
PI_BUILD_OPTIONS = \
	--architectures armhf \
	--bootstrap-qemu-arch armhf \
	--bootstrap-qemu-static /usr/bin/qemu-arm-static \
	--firmware-binary false \
	--firmware-chroot false \
	--linux-flavours "rpi rpi-rpfv rpi2-rpfv" \
	--mirror-bootstrap "http://archive.raspbian.org/raspbian" \
	--mirror-binary "http://archive.raspbian.org/raspbian" \
	--parent-mirror-bootstrap "http://archive.raspbian.org/raspbian" \
	--parent-mirror-binary "http://archive.raspbian.org/raspbian" \
	--updates false

.PHONY: clean dist-clean config

all: config pi-minimal.img

# Build using Docker
docker:
	docker build -t raspbian-live-build . && \
	docker run -t --rm -i --privileged -v $(shell pwd):/raspbian-live-build raspbian-live-build

# RPI requires fat32 for boot partition
config:
	[ -e build ] || mkdir build
	cd build && \
	env LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg" \
		lb config $(GENERAL_BUILD_OPTIONS) $(HDD_IMAGE_BUILD_OPTIONS) \
			$(PI_BUILD_OPTIONS)
	cp -rf config build/

build/live-image-armhf.img:
	( cd build && sudo lb build ) 2>&1 | tee $(BUILD_LOG)

# Add /sbin to the path for parted, because this is where it resides on some
# systems.
pi-minimal.img: build/live-image-armhf.img
	cp build/live-image-armhf.img ./pi-minimal-wip.img
	export PATH=/sbin:$$PATH; parted -s pi-minimal-wip.img set 1 lba on
	mv pi-minimal-wip.img pi-minimal.img
	rm -f pi-minimal-initrd.img-*
	rm -f pi-minimal-vmlinuz-*
	for file in build/binary/live/initrd.img-* build/binary/live/vmlinuz-*; do \
		destfile="pi-minimal-$$(basename "$$file")" ; \
		cp "$$file" "$$destfile" ; \
	done
	if [ -f /.dockerinit -a -f pi-minimal.img ]; then \
		mv pi-minimal.img /raspbian-live-build/; \
	fi

dist-clean:
	-sudo rm -rf build

clean:
	-[ -e build ] && cd build && sudo lb clean
	-sudo rm -rf build/config
	-rm -f $(BUILD_LOG)

remake-img: remake-binary-img pi-minimal.img

remake-binary-img:
	sudo mv build/binary.img build/chroot/binary.img
	sudo rm -f build/.build/binary_hdd
	cd build && sudo lb binary_hdd

