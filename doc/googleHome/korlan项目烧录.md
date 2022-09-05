


----

> 注意以下步骤都是以 korlan-p2 为例

## 下载文件

[下载地址](https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/korlan-eng/262831?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)

> 如果出现弹窗就选 美国

## 烧录

```sh
adnl.exe  Download u-boot.bin 0x10000  # 上电强制进入烧录模式  强制烧录会进入USB模式，需要重USB下载
adnl.exe run
adnl.exe bl2_boot -F  u-boot.bin
# 上面不会下载到 flash
adnl.exe oem "store init 1"
adnl.exe oem "store boot_erase bootloader"
adnl.exe oem "store erase boot 0 0"
adnl.exe oem "store erase system 0 0"
adnl.exe Partition -P bootloader  -F  u-boot.bin
adnl.exe Partition -P boot  -F boot-sign.img
adnl.exe Partition -P system  -F system.img
adnl.exe oem "reset"
```

## 单独编译 uboot 和 kernel 和签名

### 整体编译

google_source/eureka/amlogic_sdk$ ./sdk/build_scripts/build_all.sh ../chrome korlan



### 单独编译

通过查看 `./sdk/build_scripts/build_all.sh` 脚本

```sh
./bl32//build_bl32.sh korlan-b1 ../u-boot/
```

### 签名

> /mnt/nfsroot/yuegui.he

```
$ git log
commit f03c62ea2c5be9bead46eecd1d58752248630b13 (HEAD -> master)
Author: yuegui.he <yuegui.he@amlogic.com>
Date:   Wed Jun 9 21:37:01 2021 +0800

    [AML] pack uboot & kernel script
    
    you must cherry-pick https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/204823
    
    Test: bash main.sh /path/amlogic_sdk/ u-boot korlan proto /patch/chrome
    eg:
    
    case1: build & sign uboot
    bash main.sh /path/amlogic_sdk/ u-boot korlan p2 /mnt/nfsroot/yuegui.he/elaine/chrome
    
    case2: build & sign kernel
    bash main.sh /path/korlan/amlogic_sdk/ kernel korlan p2 /mnt/nfsroot/yuegui.he/elaine/chrome
    
    Signed-off-by: Yuegui He <yuegui.he@amlogic.corp-partner.google.com>
```

### main.sh

```sh
amlogic_sdk/build-sign-pdk$ ./main.sh ../amlogic_sdk u-boot korlan p2 ../../chrome

# CURRENT_DIR=/mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk
# COMPILE_DIR=$1 = ../amlogic_sdk
# COMPILE_PART=$2 = u-boot
# COMPILE_PROJECT=$3 = korlan
# COMPILE_PRO_VER=$4 = p2
# COMPILE_PRO_VER_BOARD_NAME = korlan-p2
# CHROME_DIR=$5 = ../../chrome

# OUTPUT_SIGNED_DIR=korlan/korlan-p2
```


编译流程

- u-boot
- kernel
- korlan_sign
  - uboot： ./ssign-uboot_korlan.sh
  - kernel： ./build-bootimg-sign_korlan.sh

### 编译签名步骤

vim build-sign-pdk/ssign-uboot_korlan.sh 修改路径

#### uboot

- 编译和签名 bootloader

```sh
$ cd amlogic_sdk/build-sign-pdk
$ ./main.sh ../../amlogic_sdk/ u-boot korlan p2 ../../chrome
# split uboot.bin to bl2.bin and tpl.bin
```

- 烧录 bootloader

```sh
adnl.exe  Download u-boot.bin 0x10000  # 上电强制进入烧录模式
adnl.exe run
adnl.exe bl2_boot -F  u-boot.bin

adnl.exe oem "store init 1"
adnl.exe oem "store boot_erase bootloader"
adnl.exe Partition -P bootloader  -F  u-boot.bin
```


#### kernel 

- 获取ramdisk

**注意：** 每次Google 更新都需要拷贝 boot.img

[下载地址](https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/korlan-eng;tab=objects?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)


将 D:\KendallFile\GoogleHome\internal_master_korlan-eng_309703_korlan-ota-korlan-p2-309703\boot.img 拷贝到 Z:\workspace\google_source\eureka\amlogic_sdk\unpack_boot_ramdisk_script 

然后再使用

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/unpack_boot_ramdisk_script
bash unpack_boot.sh ./boot.img ./boot_out unpack_boot 

# 进行打包，接着拷贝
cp ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk/korlan/ramdisk.img
```

- 编译和签名 kernel

```sh
$ cd amlogic_sdk/build-sign-pdk
$ ./main.sh ../../amlogic_sdk/ kernel korlan p2 ../../chrome
# cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk//kernel/arch/arm64/boot/kernel.korlan.gz-dtb.korlan-p2 ./kernel-korlan-p2.img
# to sign boot.img to korlan/korlan/korlan-p2/boot-sign.img
```

> Note: 生成的 u-boot.bin & boot-sign.img, 在 korlan/korlan-p2 下面

- 烧录kernel

```sh
#  Z:\workspace\google_source\eureka\amlogic_sdk\To_shengken_sign\korlan\korlan-p2>
adnl.exe oem "store erase boot 0 0"
adnl.exe Partition -P boot  -F .\boot-sign.img
adnl.exe oem "reset"  重启
```
