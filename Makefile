#!/bin/sh

BUILD_LOG := build.log

BUILD_OPTIONS = \
	--apt-indices none \
	--apt-secure false \
	--apt-source-archives false \
	--archive-areas 'main firmware non-free' \
	--bootappend-live "boot=live config hostname=magic username=fountain" \
	--cache-stages false \
	--compression gzip \
	--distribution wheezy \
	--gzip-options '-9 --rsyncable' \
	--mode debian \
	--security false \
	--binary-filesystem fat32 \
	--binary-images hdd \
	--chroot-filesystem squashfs \
	--hdd-size 512 \
	--initramfs live-boot \
	--system live \
	--architectures armhf \
	--bootstrap-qemu-arch armhf \
	--bootstrap-qemu-static /usr/bin/qemu-arm-static \
	--firmware-binary false \
	--firmware-chroot false

.PHONY: clean dist-clean config

all: config minimal.img

config:
	[ -e build ] || mkdir build
	[ -e config ] || mkdir config
	cd build && \
	env LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg" \
		lb config $(BUILD_OPTIONS)
	cp -rf config build/

build/binary.img:
	( cd build && sudo lb build ) 2>&1 | tee $(BUILD_LOG)

minimal.img: build/binary.img
	cp build/binary.img ./minimal-wip.img
	parted -s minimal-wip.img set 1 lba on
	mv minimal-wip.img minimal.img
	rm -f minimal-initrd.img-*
	rm -f minimal-vmlinuz-*
	for file in build/binary/live/initrd.img-* build/binary/live/vmlinuz-*; do \
		destfile="minimal-$$(basename "$$file")" ; \
		cp "$$file" "$$destfile" ; \
	done
	[ -f minimal.img ] && mv minimal.img /test-live-build/

dist-clean:
	-sudo rm -rf build

clean:
	-[ -e build ] && cd build && sudo lb clean
	-sudo rm -rf build/config
	-rm -f $(BUILD_LOG)

remake-img: remake-binary-img minimal.img

remake-binary-img:
	sudo mv build/binary.img build/chroot/binary.img
	sudo rm -f build/.build/binary_hdd
	cd build && sudo lb binary_hdd

