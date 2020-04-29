#!/bin/bash

function msg() {
    echo -e "\e[1;32m$@\e[0m"
}

clear

# Fetch kernel version from makefile -By TwistedPrime

makefile="$(pwd)/Makefile"

VERSION=$(cat $makefile | head -2 | tail -1 | cut -d '=' -f2)
PATCHLEVEL=$(cat $makefile | head -3 | tail -1 | cut -d '=' -f2)
SUBLEVEL=$(cat $makefile | head -4 | tail -1 | cut -d '=' -f2)
EXTRAVERSION=$(cat $makefile | head -5 | tail -1 | cut -d '=' -f2)
VERSION=$(echo "$VERSION" | awk -v FPAT="[0-9]+" '{print $NF}')
PATCHLEVEL=$(echo "$PATCHLEVEL" | awk -v FPAT="[0-9]+" '{print $NF}')
SUBLEVEL=$(echo "$SUBLEVEL" | awk -v FPAT="[0-9]+" '{print $NF}')
EXTRAVERSION=$(echo "$EXTRAVERSION" | awk -v FPAT="[0-9]+" '{print $NF}')

KERNELVERSION="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}${EXTRAVERSION}"

#

msg "Kernel version: $KERNELVERSION"

sudo cd

msg "Removing old configs..."

rm -rf .config
rm -rf .config.old

msg "Preparing for compilation..."

export USE_CCACHE=1
export USE_PREBUILT_CACHE=1
export PREBUILT_CACHE_DIR=~/.ccache
export CCACHE_DIR=~/.ccache
THREADS=-j$(nproc --all)
config=twisted_defconfig
FLAGS="AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip"
CLANG="CC=clang HOSTCC=clang"

cp $config .config
make localmodconfig
#make menuconfig

msg "Compiling kernel..."

sudo make $THREADS $FLAGS $CLANG 

msg "Compiling modules..."

sudo make $THREADS modules

msg "Installing modules..."

sudo make $THREADS modules_install

msg "Installing kernel..."

sudo make $THREADS install

cd /boot
sudo mkinitramfs -ko initrd.img-$KERNELVERSION $KERNELVERSION
sudo update-grub

msg "Compilation done, reboot to apply changes..."
