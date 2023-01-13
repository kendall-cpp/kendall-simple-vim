#!/bin/bash

set -e

readonly SDK_PATH="$(readlink -f $(dirname $0)/)"
########################################################
# establish build environment and build options value
# Please modify the following items according your build environment

ARCH=arm64
if [ ! -z $1 ]; then
    ARCH=$1
fi

readonly BOARD_NAME=$2
readonly WORKSPACE_PATH=$3

PRODUCT=`echo ${BOARD_NAME} | cut -d "-" -f1`

export AQROOT=`pwd`
export AQARCH=$AQROOT/arch/XAQ2

export SDK_DIR=$AQROOT/build/sdk

case "$ARCH" in

arm32)
    # arm 32
    #TOOLCHAIN_DIR=/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf
    TOOLCHAIN_DIR=/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/arm/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf
    #CROSS=${TOOLCHAIN_DIR}/bin/arm-none-linux-gnueabihf-
    ARCH=arm
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=cortex-a9
    export CPU_ARCH=armv7-a
    export FIXED_ARCH_TYPE=arm-gnueabihf

    #export KERNEL_DIR=/mnt/fileroot/shengken.lin/workspace/a5_buildroot/output/a5_av400_a6432_release/build/linux-amlogic-5.4-dev/
    export TOOLCHAIN=${TOOLCHAIN_DIR}/bin
    #export CROSS_COMPILE=$CROSS
    export CROSS_COMPILE=arm-linux-gnueabihf-
    export LIB_DIR=${TOOLCHAIN_DIR}/arm-linux-gnueabihf/libc/lib
    export PATH=$TOOLCHAIN:$PATH
;;

arm64)
    # arm64
    TOOLCHAIN_DIR=/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/aarch64/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu
    CROSS=${TOOLCHAIN_DIR}/bin/aarch64-linux-gnu-
    ARCH=arm64
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=cortex-a53
    export CPU_ARCH=armv8-a
    export FIXED_ARCH_TYPE=aarch64-gnu  # av400 is arm64

    export KERNEL_DIR=/mnt/fileroot/shengken.lin/workspace/a5_buildroot/output/a5_av400_a6432_release/build/linux-amlogic-5.4-dev/
    export CROSS_COMPILE=$CROSS
    export TOOLCHAIN=${TOOLCHAIN_DIR}/bin
    export LIB_DIR=${TOOLCHAIN_DIR}/aarch64-linux-gnu/libc/lib
    export PATH=$TOOLCHAIN:$PATH
    ;;

arm)
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=arm920
    export FIXED_ARCH_TYPE=arm

    export KERNEL_DIR=/home/software/Linux/linux-2.6.21-arm1
    export CROSS_COMPILE=arm-none-linux-gnueabi-
    export TOOLCHAIN=/home/software/Linux/toolchain
    export LIB_DIR=$TOOLCHAIN/arm-none-linux-gnueabi/libc/usr/lib
;;

arm64-debug)
    ARCH=arm64
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=cortex-a53
    export CPU_ARCH=armv8-a
    export FIXED_ARCH_TYPE=aarch64-cros-clang13
    export USE_CLANG=1
    export KERNEL_DIR=${SDK_PATH}/../kernel
    export CROSS_COMPILE=${SDK_PATH}/../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-
    export TOOLCHAIN=${SDK_PATH}/../prebuilt/toolchain/aarch64/bin
    export LIB_DIR=${SDK_PATH}/../prebuilt/toolchain/aarch64/lib
    export cc_clang=${SDK_PATH}/../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang
    export CLANG_TRIPLE=${SDK_PATH}/../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-

    # Building with symbols helps with debugging using developer workstations;
    # the build system automatically strips symbols later before copying to the
    # target's filesystem
    export CFLAGS="-g -stdlib=libc++"
    export CXXFLAGS="-g -stdlib=libc++"
    export LFLAGS="--stdlib=libc++ -Wl,--fatal-warnings -fPIC -Wl,-z,noexecstack -Wl,-z,now -Wl,-z,relro -Wl,-z,defs -pthread -Wl,-O1 -Wl,--gc-sections -Wl,--as-needed"
;;

arm-yocto)
    ARCH=arm
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=cortex-a9
    export CPU_ARCH=armv7-a
    export FIXED_ARCH_TYPE=arm-yocto

    export KERNEL_DIR=/home/software/Linux/YOCTO/L3.10.9_1.0.0_alpha_20131009
    export TOOLCHAIN=/home/software/Linux/YOCTO/poky/sysroots/x86_64-pokysdk-linux/usr
    export PATH=$TOOLCHAIN/bin:$TOOLCHAIN/bin/cortexa9hf-vfp-neon-poky-linux-gnueabi:$PATH
    export CROSS_COMPILE=arm-poky-linux-gnueabi-
    export ROOTFS=/home/software/Linux/YOCTO/x11-20130912221643
    export ROOTFS_USR=$ROOTFS/usr
    export X11_ARM_DIR=$ROOTFS/usr
    export CFLAGS="-D__ARM_PCS_VFP --sysroot=$ROOTFS"
    export LFLAGS="--sysroot=$ROOTFS"
    export PFLAGS="--sysroot=$ROOTFS"
    export FPU=vfp
    export FLOAT_ABI=hard
    BUILD_YOCTO_DRI_BUILD=1
;;

unicore)
    export ARCH_TYPE=unicore
    export CPU_TYPE=0
    export CPU_ARCH=0
    export FIXED_ARCH_TYPE=unicore

    export KERNEL_DIR=/home/software/Linux/linux-2.6.32
    export CROSS_COMPILE=unicore32-linux-
    export TOOLCHAIN=/home/software/Linux/uc4-1.0-beta-hard-RHELAS5
    export LIB_DIR=$TOOLCHAIN/unicore32-linux/lib
;;

tensilica)
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=0
    export CPU_ARCH=0
    export FIXED_ARCH_TYPE=tensilica

#    KERNEL_DIR=/home/software/Linux/linux-2.6.24.7
    CROSS_COMPILE=xtensa_venus-linux-
    TOOLCHAIN=/home/software/Linux/xtensa/staging_dir/usr
    LIB_DIR=$TOOLCHAIN/lib
;;

ppc-be)
    export ARCH_TYPE=powerpc
    export CPU_TYPE=440

    # '-be' mens big-endian
    export FIXED_ARCH_TYPE=ppc-be

    # set ENDIANNESS to build driver with little-endian
    #export ENDIANNESS=-mlittle-endian

#    KERNEL_DIR=/home/software/Linux/linux-2.6.27
    export CROSS_COMPILE=ppc_4xx-
    export TOOLCHAIN=/home/software/eldk/usr
    export DEPMOD=$TOOLCHAIN/bin/depmod.pl
    export LIB_DIR=/home/software/eldk/ppc_4xx/lib

;;

mips-le)

    export ARCH_TYPE=$ARCH
    export CPU_TYPE=0
    export ARCH_TYPE=mips
    export CPU_ARCH=34kf

    #
    # to select the right ES20 pre-built files
    #
    export FIXED_ARCH_TYPE=mips-le

    #
    # to build driver with little endin
    #
    export ENDIANNESS=-mel

    export KERNEL_DIR=/home/software/Linux/linux-2.6.19-mips.le
    export CROSS_COMPILE=mips-linux-gnu-
    export TOOLCHAIN=/home/software/Linux/mips-4.4-5
    export LIB_DIR=$TOOLCHAIN/mips-linux-gnu/libc/el/usr/lib
;;

mips-be)

    export ARCH_TYPE=$ARCH
    export CPU_TYPE=0
    export ARCH_TYPE=mips
    export CPU_ARCH=34kf

    #
    # to select the right ES20 pre-built files
    #
    export FIXED_ARCH_TYPE=mips-be

    #
    # to build driver with little endin
    #
    export ENDIANNESS=-meb

    export KERNEL_DIR=/home/software/Linux/linux-2.6.19-mips.be
    export CROSS_COMPILE=mips-linux-gnu-
    export TOOLCHAIN=/home/software/Linux/mips-4.4-5
    export LIB_DIR=$TOOLCHAIN/lib
;;

mips-le-24kc)
    export ARCH_TYPE=mips
    export CPU_ARCH=24kc
    export CPU_TYPE=0

    export FIXED_ARCH_TYPE=mips-le-24kc

    #
    #  set build optons: little-endian
    #
    export ENDIANNESS=-mel

    export KERNEL_DIR=/home/software/Linux/linux-2.6.19-mips.le
    export CROSS_COMPILE=mipsel-linux-gnu-
    export TOOLCHAIN=/home/software/Linux/tools-2.6.27
    export LIB_DIR=$TOOLCHAIN/lib
;;

*)
   echo "ERROR: Unknown $ARCH, or not support so far"
   exit 1
;;

esac;


########################################################
# set special build options valule
# You can modify the build options for different results according your requirement
#
#    option                    value   description                          default value
#    -------------------------------------------------------------------------------------
#    DEBUG                      1      Enable debugging.                               0
#                               0      Disable debugging.
#
#    NO_DMA_COHERENT            1      Disable coherent DMA function.                  0
#                               0      Enable coherent DMA function.
#
#                                      Please set this to 1 if you are not sure what
#                                      it should be.
#
#    ABI                        0      Change application binary interface, default    0
#                                      is 0 which means no setting
#                                      aapcs-linux For example, build driver for Aspenite board
#
#    LINUX_OABI                 1      Enable this if build environment is ARM OABI.   0
#                               0      Normally disable it for ARM EABI or other machines.
#
#    USE_VDK                    1      Eanble this one when the applications           0
#                                      are using the VDK programming interface.
#                               0      Disable this one when the applications
#                                      are NOT using the VDK programming interface.
#
#                                      Don't eanble gcdSTATIC_LINK (see below)
#                                      at the same time since VDK will load some
#                                      libraries dynamically.
#
#    EGL_API_FB                 1      Use the FBDEV as the GUI system for the EGL.    0
#                               0      Use X11 system as the GUI system for the EGL.
#
#    EGL_API_DRI                1      Use DRI to support X accelerator.               0
#                                      EGL_API_FB and EGL_API_DFB must be 0.
#                               0      Do not use DRI to support X accelerator.
#
#    X11_DRI3                   1      Use DRI3 framework to support X11.              0
#                               0      Do not use DRI3 framework to support X11.
#
#    EGL_API_DFB                1      Use directFB accelerator.                       0
#                                      EGL_API_FB and EGL_API_DRI must be 0.
#                               0      Do not use directFB accelerator.
#
#    gcdSTATIC_LINK             1      Enable static linking.                          0
#                               0      Disable static linking;
#
#                                      Don't enable this one when you are building
#                                      GFX driver and HAL unit tests since both of
#                                      them need dynamic linking mechanisim.
#                                      And it must NOT be enabled when USE_VDK=1.
#
#   CUSTOM_PIXMAP               1      Use the user defined Pixmap format in EGL.      0
#                               0      Use X11 pixmap format in EGL.
#
#    ENABLE_GPU_CLOCK_BY_DRIVER 1      Set the GPU clock in the driver.                0
#                               0      The GPU clock should be set by BSP.
#
#    USE_FB_DOUBLE_BUFFER       0      Use single buffer for the FBDEV                 0
#                               1      Use double buffer for the FBDEV (NOTE: the FBDEV must support it)
#
#
#    USE_PLATFORM_DRIVER        1      Use platform driver model to build kernel       1
#                                      module on linux while kernel version is 2.6.
#                               0      Use legecy kernel driver model.
#
#    FPGA_BUILD                 1      Set this option to 1 if you're running on       0
#                                      FPGA board.
#                               0
#
#    USE_BANK_ALIGNMENT         1      Enable gcdENABLE_BANK_ALIGNMENT, and video memory is allocated bank aligned.
#                                      The vendor can modify _GetSurfaceBankAlignment() and gcoSURF_GetBankOffsetBytes()
#                                      to define how different types of allocations are bank and channel aligned.
#                               0      Disabled (default), no bank alignment is done.
#
#    BANK_BIT_START             0      Use default start bit of the bank defined in gc_hal_options.h
#                    [BANK_BIT_START]  Specifies the start bit of the bank (inclusive).
#                                      This option has an effect only when gcdENABLE_BANK_ALIGNMENT is enabled;
#
#    BANK_BIT_END               0      Use default end bit of the bank defined in gc_hal_options.h
#                    [BANK_BIT_END]    Specifies the end bit of the bank (inclusive);
#                                      This option has an effect only when gcdENABLE_BANK_ALIGNMENT is enabled;
#
#    BANK_CHANNEL_BIT           0      Use default channel bit defined in gc_hal_options.h
#                  [BANK_CHANNEL_BIT]  When set to no-zero, video memory when allocated bank aligned is allocated such
#                                      that render and depth buffer addresses alternate on the channel bit specified.
#                                      This option has an effect only when gcdENABLE_BANK_ALIGNMENT is enabled.
#

BUILD_OPTION_DEBUG=0
BUILD_OPTION_ABI=0
BUILD_OPTION_LINUX_OABI=0
BUILD_OPTION_NO_DMA_COHERENT=1
BUILD_OPTION_USE_VDK=1

BUILD_OPTION_USE_VXC_BINARY=0
# GPU_CONFIG for T931 rev A is vipnanoqi_pid0x7d
# GPU_CONFIG for T931 rev B is vipnanoqi_pid0x88
# We want to support both in one build, so we must disable USE_VXC_BINARY.
# Leaving GPU_CONFIG set seems incorrect if we want to support both. I don't
# see any references to GPU_CONFIG outside of libnnvxc and libovx12. Those
# don't have any references if USE_VXC_BINARY is not set.
#BUILD_OPTION_GPU_CONFIG="vippico_v3_pid0x99"
#BUILD_OPTION_GPU_CONFIG="vipnanoqi_pid0x7d"
#BUILD_OPTION_GPU_CONFIG="vipnanoqi_pid0x88"
BUILD_OPTION_FIXED_HOST_STRING="build_ml"

if [ -z $BUILD_OPTION_EGL_API_FB ]; then
    BUILD_OPTION_EGL_API_FB=1
fi
if [ -z $BUILD_OPTION_EGL_API_DFB ]; then
    BUILD_OPTION_EGL_API_DFB=0
fi
if [ -z $BUILD_OPTION_EGL_API_DRI ]; then
    BUILD_OPTION_EGL_API_DRI=0
fi
if [ -z $BUILD_OPTION_X11_DRI3 ]; then
    BUILD_OPTION_X11_DRI3=0
fi
if [ -z $BUILD_OPTION_EGL_API_WL ]; then
    BUILD_OPTION_EGL_API_WL=0
fi
if [ -z $BUILD_OPTION_EGL_API_NULLWS ]; then
    BUILD_OPTION_EGL_API_NULLWS=0
fi
BUILD_OPTION_gcdSTATIC_LINK=0
BUILD_OPTION_CUSTOM_PIXMAP=0
BUILD_OPTION_USE_3D_VG=1
if [ -z $BUILD_OPTION_USE_OPENCL ]; then
    BUILD_OPTION_USE_OPENCL=1
fi
if [ -z $BUILD_OPTION_USE_OPENVX ]; then
    BUILD_OPTION_USE_OPENVX=1
fi
if [ -z $BUILD_OPTION_USE_VULKAN ]; then
    BUILD_OPTION_USE_VULKAN=0
fi
BUILD_OPTION_USE_FB_DOUBLE_BUFFER=0
BUILD_OPTION_USE_PLATFORM_DRIVER=1
if [ -z $BUILD_OPTION_ENABLE_GPU_CLOCK_BY_DRIVER ]; then
    BUILD_OPTION_ENABLE_GPU_CLOCK_BY_DRIVER=0
fi

if [ -z $BUILD_YOCTO_DRI_BUILD ]; then
    BUILD_YOCTO_DRI_BUILD=0
fi

BUILD_OPTION_CONFIG_DOVEXC5_BOARD=0
BUILD_OPTION_FPGA_BUILD=0
BUILD_OPTIONS="NO_DMA_COHERENT=$BUILD_OPTION_NO_DMA_COHERENT"
BUILD_OPTIONS="$BUILD_OPTIONS USE_VDK=$BUILD_OPTION_USE_VDK"
BUILD_OPTIONS="$BUILD_OPTIONS EGL_API_FB=$BUILD_OPTION_EGL_API_FB"
BUILD_OPTIONS="$BUILD_OPTIONS EGL_API_DFB=$BUILD_OPTION_EGL_API_DFB"
BUILD_OPTIONS="$BUILD_OPTIONS EGL_API_DRI=$BUILD_OPTION_EGL_API_DRI"
BUILD_OPTIONS="$BUILD_OPTIONS X11_DRI3=$BUILD_OPTION_X11_DRI3"
BUILD_OPTIONS="$BUILD_OPTIONS EGL_API_NULLWS=$BUILD_OPTION_EGL_API_NULLWS"
BUILD_OPTIONS="$BUILD_OPTIONS gcdSTATIC_LINK=$BUILD_OPTION_gcdSTATIC_LINK"
BUILD_OPTIONS="$BUILD_OPTIONS EGL_API_WL=$BUILD_OPTION_EGL_API_WL"
BUILD_OPTIONS="$BUILD_OPTIONS ABI=$BUILD_OPTION_ABI"
BUILD_OPTIONS="$BUILD_OPTIONS LINUX_OABI=$BUILD_OPTION_LINUX_OABI"
BUILD_OPTIONS="$BUILD_OPTIONS DEBUG=$BUILD_OPTION_DEBUG"
BUILD_OPTIONS="$BUILD_OPTIONS CUSTOM_PIXMAP=$BUILD_OPTION_CUSTOM_PIXMAP"
BUILD_OPTIONS="$BUILD_OPTIONS USE_3D_VG=$BUILD_OPTION_USE_3D_VG"
BUILD_OPTIONS="$BUILD_OPTIONS USE_OPENCL=$BUILD_OPTION_USE_OPENCL"
BUILD_OPTIONS="$BUILD_OPTIONS USE_OPENVX=$BUILD_OPTION_USE_OPENVX"
BUILD_OPTIONS="$BUILD_OPTIONS USE_VULKAN=$BUILD_OPTION_USE_VULKAN"
BUILD_OPTIONS="$BUILD_OPTIONS USE_FB_DOUBLE_BUFFER=$BUILD_OPTION_USE_FB_DOUBLE_BUFFER"
BUILD_OPTIONS="$BUILD_OPTIONS USE_PLATFORM_DRIVER=$BUILD_OPTION_USE_PLATFORM_DRIVER"
BUILD_OPTIONS="$BUILD_OPTIONS ENABLE_GPU_CLOCK_BY_DRIVER=$BUILD_OPTION_ENABLE_GPU_CLOCK_BY_DRIVER"
BUILD_OPTIONS="$BUILD_OPTIONS CONFIG_DOVEXC5_BOARD=$BUILD_OPTION_CONFIG_DOVEXC5_BOARD"
BUILD_OPTIONS="$BUILD_OPTIONS FPGA_BUILD=$BUILD_OPTION_FPGA_BUILD"
BUILD_OPTIONS="$BUILD_OPTIONS YOCTO_DRI_BUILD=$BUILD_YOCTO_DRI_BUILD"
BUILD_OPTIONS="$BUILD_OPTIONS USE_VXC_BINARY=$BUILD_OPTION_USE_VXC_BINARY"
BUILD_OPTIONS="$BUILD_OPTIONS GPU_CONFIG=$BUILD_OPTION_GPU_CONFIG"
if [ ! -z $BUILD_OPTION_FIXED_HOST_STRING ]; then
  BUILD_OPTIONS="$BUILD_OPTIONS HOST=$BUILD_OPTION_FIXED_HOST_STRING"
fi

export PATH=$TOOLCHAIN:$PATH

########################################################
# clean/build driver and samples
# build results will save to $SDK_DIR/
#
cd $AQROOT; make -j1 -f makefile.linux $BUILD_OPTIONS clean
cd $AQROOT; make -j40 -f makefile.linux $BUILD_OPTIONS install 2>&1 | tee $AQROOT/linux_build.log
#cd $AQROOT; make -j1 -f makefile.linux $BUILD_OPTIONS clean
#cd $AQROOT; make -j1 CC=${cc_clang} HOSTCC=${cc_clang} LD=${CROSS_COMPILE}ld.lld NM=${TOOLCHAIN}/llvm-nm OBJCOPY=${TOOLCHAIN}/llvm-objcopy CLANG_TRIPLE=${CLANG_TRIPLE} CROSS_COMPILE=${CROSS_COMPILE} -f makefile.linux $BUILD_OPTIONS install 2>&1 | tee $AQROOT/linux_build.log

########################################################
# clean/build acuity-ovxlib-dev
#
cd acuity-ovxlib-dev/
if [ "$1"x = "arm64"x ]
then
    bash build_vx.sh
elif [ "$1"x = "arm32"x ]
then
    bash build_vx.sh $1
else
    echo "Please input 'ARCH'!!!"
    exit 0
fi
cd ../

########################################################
# other build/clean commands to build/clean specified items, eg.
#
# cd $AQROOT; make -f makefile.linux $BUILD_OPTIONS gal_core V_TARGET=clean || exit 1
# cd $AQROOT; make -f makefile.linux $BUILD_OPTIONS gal_core V_TARGET=install || exit 1

# Install SDK

PREBUILT_PATH=${WORKSPACE_PATH}/vendor/amlogic/${PRODUCT}/prebuilt

# Use rsync for includes and nnvxc_kernels because files may be both added and
# removed over time.
mkdir -p "${PREBUILT_PATH}/sdk/include"
rsync -r --delete -- \
  "${AQROOT}/build/sdk/include"/* \
  "${PREBUILT_PATH}/sdk/include"
if (( BUILD_OPTION_USE_VXC_BINARY == 0 )); then
  mkdir -p "${PREBUILT_PATH}/sdk/nnvxc_kernels"
  rsync -r --delete -- \
    "${AQROOT}/build/sdk/nnvxc_kernels" \
    "${PREBUILT_PATH}/sdk"
elif [[ -d "${PREBUILT_PATH}/sdk/nnvxc_kernels" ]]; then
  # nnvxc_kernels is only required if USE_VXC_BINARY=0, so we should not leave
  # them in place if they are not being used
  echo "WARNING: ${PREBUILT_PATH}/sdk/nnvxc_kernels is present, but" \
       "USE_VXC_BINARY is set" >&2
fi

LIBRARY_PATH=${PREBUILT_PATH}/sdk/lib64/
mkdir -p ${LIBRARY_PATH}
cp $AQROOT/build/sdk/drivers/*.so.* $LIBRARY_PATH
#cp $AQROOT/acuity-ovxlib-dev/lib/*.so $LIBRARY_PATH
# Exclude jpeg includes, which are used by the tests but not ovxlib
rsync -r --delete --exclude 'j*.h' -- \
  "${AQROOT}/acuity-ovxlib-dev/include"/* \
  "${PREBUILT_PATH}/sdk/include"

KERNEL_MODULE_PATH=$PREBUILT_PATH/kernel/modules
mkdir -p ${KERNEL_MODULE_PATH}
cp $AQROOT/galcore.ko $KERNEL_MODULE_PATH/galcore.$BOARD_NAME.ko

FACTORY_KERNEL_MODULE_PATH=$PREBUILT_PATH/factory/kernel/modules
mkdir -p ${FACTORY_KERNEL_MODULE_PATH}
cp $AQROOT/galcore.ko $FACTORY_KERNEL_MODULE_PATH/galcore.$BOARD_NAME.ko
