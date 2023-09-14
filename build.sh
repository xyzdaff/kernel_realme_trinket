#!/bin/bash
#
# Compile script for Mandriva Kernel
# Copyright © 2022-2023

# Initializing variables
SECONDS=0 # builtin bash timer
ZIPNAME="Mandriva-$(date '+%Y%m%d').zip"
TC_DIR="$HOME/toolchains/neutron-clang"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="vendor/RMX1911_defconfig"
export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER=Whodaff
export KBUILD_BUILD_HOST=Trinket

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
 ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi
	
# Sync submodule for KernelSU
git submodule init && git submodule update

if [[ $1 = "-r" || $1 = "--regen" ]]; then
  make O=out ARCH=arm64 $DEFCONFIG savedefconfig
  cp out/defconfig arch/arm64/configs/$DEFCONFIG
  exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
  rm -rf out
fi

# Compile Kernel
mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img

# Packging Kernel
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
  if [ -d "$AK3_DIR" ]; then
    cp -r $AK3_DIR AnyKernel3
  elif ! git clone -q https://github.com/xyzdaff/AnyKernel3; then
    echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
    exit 1
  fi
  cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
  cp out/arch/arm64/boot/dtbo.img AnyKernel3
  rm -f *zip
  cd AnyKernel3
  git checkout master &> /dev/null
  zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
  cd ..
  rm -rf AnyKernel3
  rm -rf out/arch/arm64/boot
fi

# Upload kernel to Keep.sh & Telegram
BOT_TOKEN="6462212902:AAFQ5PgZ3FEHbBkAEV6tlblPXV4OgHP8sNY"
  curl --progress-bar -F chat_id="-1001942087920" -F document=@"$ZIPNAME" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
    echo -e "\nDone!"
  else
    echo -e "\nUploading the ZIP file to keep.sh..."
    curl --upload-file $ZIPNAME https://free.keep.sh
    echo -e "\nDone!"