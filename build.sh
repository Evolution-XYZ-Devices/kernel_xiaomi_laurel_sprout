#!/bin/bash

PWD=$(pwd)
ARCH=arm64
CONFIG=vendor/laurel_sprout-perf_defconfig
TC_CLANG=$PWD/../clang
TC_GCC_ARM64=$PWD/../gcc
TC_GCC_ARM32=$PWD/../gcc-arm
OUTDIR=$PWD/output
color_failed=$'\E'"[0;31m"
color_success=$'\E'"[0;32m"
color_reset=$'\E'"[00m"
       
# picked from this commihttps://github.com/Jebaitedneko/android_kernel_xiaomi_olive/commit/823db672576da0c882f953f2938b233785b29add#diff-4d2a8eefdf2a9783512a35da4dc7676a66404b6f3826a8af9aad038722da6823 (credit:  Jebaitedneko @ github)
YYLL1=$PWD/scripts/dtc/dtc-lexer.lex.c_shipped
YYLL2=$PWD/scripts/dtc/dtc-lexer.l
[ -f $YYLL1 ] && sed -i "s/extern YYLTYPE yylloc/YYLTYPE yylloc/g;s/YYLTYPE yylloc/extern YYLTYPE yylloc/g" $YYLL1
[ -f $YYLL2 ] && sed -i "s/extern YYLTYPE yylloc/YYLTYPE yylloc/g;s/YYLTYPE yylloc/extern YYLTYPE yylloc/g" $YYLL2

[ ! -d $TC_CLANG ] && {
    echo "Cloning AOSP Clang..."
    mkdir -p $TC_CLANG && wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/android-10.0.0_r3/clang-r353983c.tar.gz -O clang.tar.gz && tar -xzf clang.tar.gz -C "$TC_CLANG" && rm clang.tar.gz

}

[ ! -d $TC_GCC_ARM64 ] && {
    echo "Cloning 64-bit GCC..."
    git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 --depth=1 "$TC_GCC_ARM64"

}

[ ! -d $TC_GCC_ARM32 ] && {
    echo "Cloning 32-bit GCC..."
        git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 --depth=1 "$TC_GCC_ARM32"

}


export PATH="$TC_CLANG/bin:$TC_GCC_ARM64/bin:$TC_GCC_ARM32/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64

[ -e $OUTDIR/.config ] && {
    echo "Previous Generated .CONFIG Detected!!!"
    echo "Do you want to Dirty Build??"
    read -rp "Choose Your Choice[y/n]: " choice
    case ${choice} in
      Y|y) echo "Here Comes The Dirty Build" ;;
      N|n) echo "Cleaning the source..." && make clean mrproper O=output ;;
    esac
}


[ ! -e $OUTDIR/.config ] && {
    echo "Generating new config from $CONFIG.."
    make $CONFIG O=output
}

read -p "Do You want To Run Menuconfig? [y|n]: " opt

case ${opt} in
     Y|y) echo "Running menuconfig..." && make menuconfig O=output ;;
     N|n) echo "Skipping..."
esac


[ -e $OUTPUT/.config ] && {
    echo "Starting Compilation..."
    make -j$(nproc --all) CC="ccache $TC_CLANG/bin/clang" CROSS_COMPILE=$TC_GCC_ARM64/bin/aarch64-linux-android- CLANG_TRIPLE=$HOME/clang/bin/aarch64-linux-gnu- CROSS_COMPILE_ARM32=$TC_GCC_ARM32/bin/arm-linux-androideabi- O=output
ret=$?

if [ $ret -eq 0 ] && [ "$?" -eq 0 ] ; then
        echo -n "${color_success}#### build completed successfully"
        echo " ####${color_reset}"
        [ -d $PWD/.git ] && git restore $YYLL1 $YYLL2
    else
        echo -n "${color_failed}#### failed to build some targets"
        echo " ####${color_reset}"
fi
}

