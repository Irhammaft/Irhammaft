#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="venoom-suryaZ-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="/root/kernel/clang"
GCC_64_DIR="/root/kernel/64"
GCC_32_DIR="/root/kernel/32"
AK3_DIR="/root/kernel/AnyKernel3"
DEFCONFIG="surya_defconfig"

export PATH="$TC_DIR/bin:$PATH"
export CCACHE_DIR="/root/.cache/ccache"
export CA="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache:$PATH"
export KBUILD_COMPILER_STRING="/root/kernel/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"


if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/venoom/AnyKernel3 -b surya; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
	cp $kernel $dtbo AnyKernel3
	cp $dtb AnyKernel3/dtb
	rm -rf out/arch/arm64/boot
	cd AnyKernel3
	git checkout surya &> /dev/null
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	[ -x "$(command -v gdrive)" ] && gdrive upload --parent 1cER1gUCA26jHfvewPaVPzwyUwFV8hUQD "$ZIPNAME"
else
	echo -e "\nCompilation failed!"
	exit 1
fi
