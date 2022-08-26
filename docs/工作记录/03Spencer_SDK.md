- [编译签名烧录](#编译签名烧录)
    - [1、sync spencer code](#1sync-spencer-code)
  - [2、Build SDK](#2build-sdk)
    - [2.1 Bootloader (bl2 + bl31 + bl32 + u-boot)](#21-bootloader-bl2--bl31--bl32--u-boot)
    - [2.2 Kernel](#22-kernel)
    - [2.3 Kernel module - NN](#23-kernel-module---nn)
  - [3.签名](#3签名)
    - [3.1 签名u-boot](#31-签名u-boot)
    - [3.2 签名kernel](#32-签名kernel)
      - [3.2.1 获取生成ramdisk](#321-获取生成ramdisk)
  - [4、烧录](#4烧录)
- [测试模型](#测试模型)

---

> 波特率：921600

# 编译签名烧录

### 1、sync spencer code

```sh
mkdir spencer-sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b spencer-master -m combined_sdk.xml
repo sync

# Note:
# Some git are Google International only, so we cannot download them.
# And you will see some error message about "repo sync"
# If you want to skip it, you can remove it from "~/eureka/spencer-sdk/.repo/manifests/combined_sdk.xml".
 --- a/combined_sdk.xml
 +++ b/combined_sdk.xml
 @@ -14,7 +14,5 @@
    <project name="amlogic/lloyd-isp" path="lloyd-isp" revision="spencer-master"/>
    <project name="verisilicon-sdk" path="verisilicon" revision="6.4.2"/>
    <project name="amlogic/freertos" path="freertos" revision="spencer-master"/>
 -  <project name="amlogic/lloyd-proprietary-3a" path="lloyd-3a" revision="spencer-master"/>
 -  <project name="xtensa-tools" path="amlogic/xtensa" revision="master"/>
    <project name="external/flatbuffers" path="amlogic/flatbuffers" revision="quartz-master"/>
  </manifest>
```

## 2、Build SDK

### 2.1 Bootloader (bl2 + bl31 + bl32 + u-boot)

```sh
# build without "release"，Default compilation option will enable logs. 

cd ~/eureka/spencer-sdk/
 
cd bl2
./build_bl2.sh spencer-p2 release
cd -
 
cd bl31
./build_bl31.sh spencer-p2 release
cd -
 
cd bl32
./build_bl32.sh spencer-p2 release
cd -
 
cd u-boot
./build_uboot.sh spencer-p2 ./../../chrome release
cd -
```

### 2.2 Kernel

```sh
# 切换分支
git branch -a | grep spencer

git checkout -t remotes/eureka-partner/spencer-master


cd ~/eureka/spencer-sdk/
 
cd kernel
./build_kernel.sh spencer-p2 ./../../chrome
```

### 2.3 Kernel module - NN

```sh
cd ~/eureka/spencer-sdk/
 
cd verisilicon
./build_ml.sh arm64 spencer-p2 ./../../chrome
cd -
```

## 3.签名

> Notes: 首先需要先获取到pdk编译脚本，这里以 spencer-p2 为例

### 3.1 签名u-boot

```sh
cd chrome/pdk
# mkdir -p ../out/host/linux-x86/bin/

chrome$ tree out/host/
out/host/
└── linux-x86
    └── bin
        ├── kernel_iv.bin
        ├── kernel_iv.txt
        ├── mkbootimg
        ├── pem_extract_pubkey.py
        ├── sign-boot-g12a-dev.sh
        └── sign-boot-g12a.sh

# 编译签名uboot
cd pdk
./create-uboot.sh -b  spencer-p2
```

![](../img/spencer-uboot编译.png)

### 3.2 签名kernel

#### 3.2.1 获取生成ramdisk

下载最新的 ramdisk

> https://console.cloud.google.com/storage/browser/_details/cast-partner-amlogic-internal/internal/master/spencer-eng/314706/factory/spencer-fct-spencer-p2-314706.zip;tab=live_object

解压后将 fct_boot.img 拷贝到 chrome/pdk/unpack_boot 目录下，

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk/unpack_boot
unpack_boot.sh ./fct_boot.img ./boot_out unpack_boot    ## 注意修改脚本路径
cp ramdisk.img ../../chrome/out/target/product/spencer/boot_unpack/

## /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
./build-bootimg.sh -b spencer-p2
```

## 4、烧录

烧录路径

> workspace/google_source/eureka/chrome/out/target/product/spencer/upgrade

烧录命令

> upgrade 中没有的 misc.img 和 fct_boot.img  在刚刚下载加压出来的文件夹中。

```sh
adnl.exe  Download u-boot.signed.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F  u-boot.signed.bin


# echo off
# ping 0.0.0.0 -n 5 > null
# echo on

adnl.exe oem "store init 1"
adnl.exe oem "mmc dev 1"

# 如果不单独编译dts这个可以不用执行，因为 dtb 已经打包到 u-boot.signed.bin
# adnl.exe Partition -M mem -P 0x1000000 -F spencer-p2.dtb
# adnl.exe oem "emmc part_write 0x1000000"

# echo off
# ping 0.0.0.0 -n 5 > null
# echo on

adnl.exe  Partition -M mem -P 0x2000000 -F u-boot.signed.bin
adnl.exe oem "store boot_write bootloader 0x2000000 0x1ffe00"

# echo off
# ping 0.0.0.0 -n 3 > null

adnl.exe Partition -P tpl_a  -F tpl.signed.bin
adnl.exe Partition -P tpl_b  -F tpl.signed.bin
adnl.exe Partition -P boot_a  -F boot.img
adnl.exe Partition -P boot_b  -F boot.img
adnl.exe Partition -P misc  -F misc.img
adnl.exe Partition -P system_b  -F fct_boot.img
adnl.exe oem "enable_factory_boot"
adnl.exe oem "reset"
```


关闭日志：dmesg -n 1


# 测试模型

最终生成的 ko 文件路径

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/factory/kernel/modules/galcore.spencer-p2.ko
```

```sh
# 切换分支
git checkout -t  remotes/eureka-partner/6.4.9
```


下载加压

push 到开发板

adb.exe push alexnet_caffe_a1 /data


