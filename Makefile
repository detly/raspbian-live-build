#!/bin/sh

BUILD_LOG := build.log

BUILD_OPTIONS = \
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

.PHONY: clean dist-clean config build

all: config build

config:
	[ -e build ] || mkdir build
	[ -e config ] || mkdir config
	cd build && \
	env LB_BOOTSTRAP_INCLUDE="apt-transport-https gnupg" \
		lb config $(BUILD_OPTIONS)
	cp -rf config build/

build:
	( cd build && sudo lb build ) 2>&1 | tee $(BUILD_LOG)

dist-clean:
	-sudo rm -rf build

clean:
	-[ -e build ] && cd build && sudo lb clean
	-sudo rm -rf build/config
	-rm -f $(BUILD_LOG)
