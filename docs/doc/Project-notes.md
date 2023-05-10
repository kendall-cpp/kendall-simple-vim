## BuildRoot

```sh
git config --local user.name "shengken.lin"
git config --local user.email shengken.lin@amlogic.com

git config --global user.name "shengken.lin"
git config --global user.email "shengken.lin@amlogic.com"
```

## A1-sync

```sh
$mkdir BuildRoot_A1

$pushd BuildRoot_A1

$repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m default.xml --repo-url=git://git.myamlogic.com/tools/repo.git

$repo sync

vim a1_buildroot/.repo/repo/.git/config
[user]
    name = shengken.lin
    email = shengken.lin@amlogic.com

git push review HEAD:refs/for/amlogic-4.19-dev
```

## A5-sync

```sh
mkdir a5_buildroot
cd a5_buildroot
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m default.xml --repo-url=git://git.myamlogic.com/tools/repo.git
repo sync

#push buildroot
git push review HEAD:refs/for/master

git remote add review ssh://shengken.lin@scgit.amlogic.com:29418/kernel/common.git
git remote add review ssh://shengken.lin@scgit.amlogic.com:29418/linux/buildroot.git
git remote add review ssh://shengken.lin@scgit.amlogic.com:29418/uboot.git
git add xxx
git commit -s --no-verify
git push review HEAD:refs/for/amlogic-5.4-dev --no-thin  # kernel

git pull amlogic HEAD:refs/for/amlogic-5.4-dev
```

### build A5

```sh
source setenv.sh 
select 11. a5_av400_a6432_release
make

后面的测试都选  a5_av400_spk_a6432_release
```

## A4

编译参考：https://confluence.amlogic.com/pages/viewpage.action?spaceKey=PM&title=A4+buildroot+compile+guide

```sh
mkdir a4_buildroot
cd a4_buildroot
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m default.xml --repo-url=git://git.myamlogic.com/tools/repo.git
repo sync

cd a4_buildroot/buildroot
wget http://walle01-sz.amlogic.com:8080/dl.tgz
tar -xf ./dl.tgz
```

### 编译

```sh
# BA400
source setenv.sh a4_ba400_spk_a6432_release
# BA409
source setenv.sh  a4_ba409_a6432_release

make
```

### A4 USB 架构

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/USB架构图-yuegui.3676mln75qm0.webp)

```c
crg_phy_20 {
	compatible = "amlogic, amlogic-crg-drd-usb2";
	
}
crg3_phy_20 {
	compatible = "amlogic, amlogic-crg-drd-usb3";	
}
crg20_otg {
	compatible = "amlogic, amlogic-crg-otg";
}
crg2_drd {
	usb-phy = <&crg_phy_20>, <&crg3_phy_20>;
	clock-src = "usb3.0";
}
crg_phy_21 {
	compatible = "amlogic, amlogic-crg-drd-usb2";
}
crg3_phy_21 {  // 为了满足 usb 物理上的需要，必须加上一个伪装的，实际上不适用 USB3.0
	compatible = "amlogic, amlogic-crg-drd-usb3";
}
crg21_drd {
	usb-phy = <&crg_phy_21>, <&crg3_phy_21>;
}
crg_udc_2 {
	compatible = "amlogic, crg_udc";
}
```

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/a4-usb-phy.766tkswb6hc0.webp)

#### 对比 AV400 的 usb-phy 控制器 关系

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/av400-usb.7cff1q8iejk0.webp)

## C3-sync

```sh
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m br-ipc-c3.xml --repo-url=git://git.myamlogic.com/tools/repo.git

# 有refapp
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m br-ipc-c3-refapp.xml --repo-url=git://git.myamlogic.com/tools/repo.git

# 修改 git user email
# vim buildRoot_C3/.repo/repo/.git/config
[user]   
        name = shengken.lin
        email = shengken.lin@amlogic.com 
```

### C3-MBP

```sh
# 编译
make linux-rebuild
make mbd-adla-rebuild 
make mbd-audio-rebuild 
make mbd-base-rebuild 
make mbd-camera-rebuild 
make mbd-cve-rebuild 
make mbd-dewarp-rebuild 
make mbd-ge2d-rebuild 
make mbd-ppu-rebuild 
make mbd-region-rebuild 
make mbd-venc-rebuild 
make mbd-vpu-rebuild  
make pmz-rebuild

make mbi-rebuild
make ipc-reference-rebuild


make

make show-targets # 查看所有package
```

### 停止 refapp

```
# /etc/init.d/S81ipc-refapp  stop
```


## wpa_cli连接wifi

```sh
wpa_cli -iwlan0 remove_network 0
wpa_cli -iwlan0 add_network 0
wpa_cli -iwlan0 set_network 0 ssid '"Amlogic-vpn04_5G"'
wpa_cli -iwlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -iwlan0 set_network 0 psk '"Aml1234566"' 
wpa_cli -iwlan0 set_network 0 pairwise CCMP
wpa_cli -iwlan0 set_network 0 group CCMP
wpa_cli -iwlan0 set_network 0 proto RSN
wpa_cli -iwlan0 enable_network 0
wpa_cli -iwlan0 status
wpa_cli -iwlan0 save
dhcpcd wlan0

wpa_cli -iwlan0 remove_network 0
wpa_cli -iwlan0 add_network 0
wpa_cli -iwlan0 set_network 0 ssid '"kendall"'
wpa_cli -iwlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -iwlan0 set_network 0 psk '"12345678"' 
wpa_cli -iwlan0 set_network 0 pairwise CCMP
wpa_cli -iwlan0 set_network 0 group CCMP
wpa_cli -iwlan0 set_network 0 proto RSN
wpa_cli -iwlan0 enable_network 0
wpa_cli -iwlan0 status
wpa_cli -iwlan0 save
dhcpcd wlan0
```



## 提交gerrit


> - https://scgit.amlogic.com/#/admin/projects/kernel/common
> - git clone ssh://shengken.lin@scgit.amlogic.com:29418/kernel/common

```sh
git config --local user.email "shengken.lin@amlogic.com"

git config --local user.name "shengken.lin"

# 或者到这个目录下添加 BuildRoot_A1-v2/.repo/repo/.git/config
[user]
    name = shengken.lin
    email = shengken.lin@amlogic.com


# 第二个会提示：fatal: remote review already exists.
# git remote add origin url  类似
git remote add review ssh://shengken.lin@scgit.amlogic.com:29418/kernel/common.git
git remote add review ssh://shengken.lin@scgit.amlogic.com:29418/linux/buildroot.git
git remote add review ssh://shengken.lin@scgit.amlogic.com:29418/uboot.git



git branch -a | grep amlogic-4.19-dev  # git branch -a 查看远程分支
git checkout -t remotes/amlogic/amlogic-4.19-dev  # 切换分支
git branch  # 查看分支
git status
git add   # add 修改的文件
git commit --amend -s   # -s 代表添加当前用户
git push review HEAD:refs/for/amlogic-4.19-dev  # kernel的提交分支
```

- uboot分支名 amlogic-4.19-dev
- kernel 分支名 amlogic-4.19-dev
- 提交查看：https://scgit.amlogic.com/#/dashboard/self

## 设置log级别

```sh
# 设置log 级别
echo 9 > /proc/sys/kernel/printk
echo 0 > /proc/sys/kernel/printk
```



# Google git

```sh
git config --local user.name "Shengken Lin"
git config --local user.email shengken.lin@amlogic.corp-partner.google.com

git config --global user.name "Shengken Lin"
git config --global user.email "shengken.lin@amlogic.corp-partner.google.com"

git pull eureka-partner korlan-master 
git push eureka-partner HEAD:refs/for/korlan-master

git push eureka-partner HEAD:refs/for/korlan-master-5.15 
git push eureka-partner HEAD:refs/for/korlan-master-5.15-drivers

```



-----

# Korlan

## korlan Sync

参考：[Sync chrome and korlan](https://confluence.amlogic.com/display/SW/Sync+chrome+and+korlan)

```sh
cd eureka && mkdir korlan-sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b korlan-master -m combined_sdk.xml
repo sync
```

> Baud rate 为 115200

## 编译korlan-4.19

```sh
cd bl2
./build_bl2.sh korlan-b1 ../u-boot release
cd -
#输出 cp ./aml_ddr.fw ../u-boot/fip/a1/

cd bl31
./build_bl31.sh korlan-b1 ../u-boot release
cd -
# 输出：cp -v build/c2/release/bl31.img ../u-boot/fip/a1/


cd bl32
./build_bl32.sh korlan-b1 ../u-boot release 
cd -
# 输出： cp -v out/bl32.img ../u-boot/fip/a1/
# 如果error: scripts/render_font.py 
# 修改pthon脚本 scripts/pack_kpub.py  #+#!/usr/bin/env python

cd u-boot
./build_uboot.sh korlan-b1 ../../chrome release
cd -
# 编译： # ./mk a1_korlan_b1 --board_name korlan-b1 --bl2 fip/a1/bl2.bin --bl30 fip/a1/bl30.bin --bl31 fip/a1/bl31.img --bl32 fip/a1/bl32.img release
# 输出： /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/korlan/prebuilt/bootloader

cd kernel
./build_kernel.sh korlan-b1  ../../chrome
cd -

# 使用 make menuconfig 4.19
make  CLANG_TRIPLE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- CC=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang CROSS_COMPILE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- ARCH=arm64 korlan-bx_defconfig CONFIG_DEBUG_SECTION_MISMATCH=y menuconfig
```

- 整体编译

```sh
cd korlan-sdk
./sdk/build_scripts/build_all.sh ../chrome korlan
```

## 编译korlan-5.15

```sh
# 整体编译
./sdk/build_scripts/build_all.sh ../chrome/ korlan --kernel=5.15
 
# chrome ota 包
source build/envsetup.sh 
lunch  # 选korlan-eng
PARTNER_BUILD=true BOARD_NAME=korlan-p2 make -j30 otapackage KERNEL_VERSION=5.15

# 编译
# bl2
./build_bl2.sh korlan-p2 ../u-boot release

cd bl31
./build_bl31.sh korlan-p2 ../u-boot release
cd -

cd bl32
./build_bl32.sh korlan-p2 ../u-boot release 

cd u-boot
./build_uboot.sh korlan-p2 ../../chrome release
cd -

# kernel
cd kernel-5.15
./build_kernel.sh korlan-p2 ../../chrome

# 使用 make menuconfig 5.15
make  CLANG_TRIPLE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- CC=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang CROSS_COMPILE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- ARCH=arm64 korlan-p2_defconfig CONFIG_DEBUG_SECTION_MISMATCH=y menuconfig
```



## 制作 ramdisk


【下载地址】: https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/korlan-eng;tab=objects?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false

将下载解压出来的 boot.img 拷贝到 unpack_boot_ramdisk_script 目录下

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/unpack_boot_ramdisk_script
bash unpack_boot.sh ./boot.img ./boot_out unpack_boot 

# 解压出ramdisk.img.xz 之后，拷贝
cp ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka-v2/korlan-sdk/build-sign-pdk/korlan/ramdisk.img
# cp ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/build-sign-pdk/korlan/ramdisk.img

## 注意5.15制作ramdisk需要将对应的ko拷贝到ramdisk 中的 /lib/modules 下
# 还需要替换 early_load_ko-5.15.rc
# vim vendor/amlogic/korlan/early_load_ko_5.15.rc 
cd /korlan-sdk/unpack_boot_ramdisk_script
python3 copy-ko-ramdisk-5.15.py
cd ramdisk_img  

```

## 签名korlan

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk
mkdir -p ./korlan/korlan-b1

# 签名 uboot
./sign-uboot.sh ../../chrome ./korlan/korlan-b1 b1
./sign-uboot.sh ../../chrome ./korlan/korlan-p2 p2

# 可能报错
#/chrome/vendor/amlogic/common/tools/signing/create-bl-a113l.sh: line 116: /mnt/fileroot/shengken.lin/workspace/google_source/eureka-v2/chrome/vendor/amlogic/common/tools/signing/../../../..//vendor/amlogic/common/tools/signing/signing-tool-g12a/sign-boot-g12a.sh: No such file or directory
vim vendor/amlogic/common/tools/signing/create-bl-a113l.sh
readonly andrtop="${script_dir}/../../../../../" 

# 签名kernel
# 打包 ramdisk
# find . |cpio -ov -H newc | xz -9  --check=crc32  > ../ramdisk.img
# ramdisk 需要拷贝到 ./korlan/ramdisk.img
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/build-sign-pdk
# ./sign-kernel.sh ../../korlan-sdk korlan/korlan-b1 b1 ../../chrome
./sign-kernel-5.15.sh ../../korlan-sdk korlan/korlan-p2 p2 ../../chrome
```

## 烧录korlan

```sh
# 强制进入烧录模式
adnl.exe  Download u-boot.bin 0x10000  
adnl.exe run
adnl.exe bl2_boot -F  u-boot.bin

# 上面不会下载到 flash
# 通过 reboot update 进入烧录模式
adnl.exe oem "store init 1"
adnl.exe oem "store boot_erase bootloader"
adnl.exe oem "store erase boot 0 0"
adnl.exe oem "store erase system 0 0"
adnl.exe Partition -P bootloader  -F  u-boot.bin
adnl.exe Partition -P boot  -F boot.img
adnl.exe Partition -P system  -F system.img
adnl.exe oem "reset"

# 定义自己的分区和烧录
adnl.exe oem "store erase system_1 0 0"
adnl.exe Partition -P system_1  -F erofs.img
# 关闭工厂模式 如果之前设置了工厂模式
# adnl.exe oem "store erase fts  0 0"

# 烧录工厂模式
adnl.exe  Download u-boot.bin 0x10000  
adnl.exe run
adnl.exe bl2_boot -F  u-boot.bin

adnl.exe oem "store init 1"
adnl.exe oem "store boot_erase bootloader"
adnl.exe oem "store erase boot 0 0"
adnl.exe oem "store erase system 0 0"
# cat u-boot.bin.usb.bl2 u-boot.bin.usb.tpl > u-boot.bin
adnl.exe Partition -P bootloader  -F  u-boot.bin
# adnl.exe Partition -P system  -F fct_boot.img
adnl.exe Partition -P system  -F boot-sign.img    # 自己编的kernel
adnl.exe oem "enable_factory_boot"

# 如果reboot update无法进入烧录模式
fts -s bootloader.command  # 设置bootloader.command 为空，工厂模式可能重启进不了kernel
fts -i  #清除工厂模式
# 或者
reboot bootloader;   # 进入uboot
adnl   # 进入烧录模式
```

## 编译korlan-chrome-ota

```sh
# 先设置JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
 export PATH=/mnt/fileroot/shengken.lin/workspace/google_source/eureka-v2/chrome/build/bin/:$PATH
 export PATH=/mnt/fileroot/shengken.lin/workspace/google_source/eureka-v2/chrome/prebuilt/toolchain/aarch64/bin/:$PATH 
 # export depot_path 也需要

cd chrome
source build/envsetup.sh 

# 全部编译 korlan-eng
lunch  # 选korlan-eng

rm ./chromium/src/out_chromecast_korlan/release/gen/chromecast/internal/build/ota/iot/iot_dock_add_to_ota_stamp.d
PARTNER_BUILD=true BOARD_NAME=korlan-b1 make -j30 otapackage  
# 输出obj路径： /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/korlan
# 如果出现 java version 问题，就是 out/host/linux-x86 的 dumpkey.jar  signapk.jar 替换过了，需要替换回repo sync 时候的 linux-x86 就可以了

可以直接使用脚本
source build-chrome.sh
lunch 16


# 转变 kernel4.19 & 5.15 to build,
    You need do this follow,
rm out/target/product/korlan/recovery/root -rf
rm out/target/product/korlan/root -rf
rm out/target/product/korlan/obj/PACKAGING -rf
rm  ./chromium/src/out_chromecast_korlan/release/gen/chromecast/internal/build/ota/iot/iot_dock_add_to_ota_stamp.d
PARTNER_BUILD=true BOARD_NAME=korlan-p2 make -j30 otapackage KERNEL_VERSION=5.15
 
# 4.19
rm out/target/product/korlan/recovery/root -rf
rm out/target/product/korlan/root -rf
rm out/target/product/korlan/obj/PACKAGING -rf
rm  ./chromium/src/out_chromecast_korlan/release/gen/chromecast/internal/build/ota/iot/iot_dock_add_to_ota_stamp.d
PARTNER_BUILD=true BOARD_NAME=korlan-b1 make -j30 otapackage
```

### 5.15 korlan5.15-ota

```sh
# kernel 5.15 chrome ota
# kernel-5.15分支切换成 korlan-master-5.15
# kernel-5.15/common_drivers分支切换成 korlan-master-5.15-drivers
# 整体编译 
./sdk/build_scripts/build_all.sh ../chrome/ korlan --kernel=5.15
# 再执行 PARTNER_BUILD=true BOARD_NAME=korlan-p2 make -j30 otapackage KERNEL_VERSION=5.15  这一步
cd chrome
source build/envsetup.sh 
# rm out/target/product/korlan/recovery/root -rf
# rm out/target/product/korlan/root -rf
# rm out/target/product/korlan/obj/PACKAGING -rf
# 删掉之后需要重新编译 korlan
PARTNER_BUILD=true BOARD_NAME=korlan-b1 make -j30 otapackage KERNEL_VERSION=5.15

# error 1 
# clang++-14: error: invalid linker name in argument '-fuse-ld=lld'
# [build/core/shared_library.mk:101: out/target/product/korlan/obj/SHARED_LIBRARIES/libz_intermediates/LINKED/libz.so] Error 1
# 解决：添加 chrome/prebuilt/toolchain/aarch64/bin 到环境变量中

# error 2
#*** No rule to make target 'vendor/amlogic/korlan/prebuilt/kernel_5.15/kernel.korlan.gz-dtb.korlan-proto', needed by 'out/target/product/korlan/root/lib/kernel/kernel-korlan-proto'.  Stop.
# 编译的时候不是编译 p2 b3 b4 
cd kernel-5.15
./build_kernel.sh korlan-b1 ../../chrome
./build_kernel.sh korlan-p2 ../../chrome
./build_kernel.sh korlan-b3 ../../chrome
./build_kernel.sh korlan-b4 ../../chrome

#error 3
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
ninja: Entering directory `/mnt/fileroot/shengken.lin/workspace/google_source/eureka-v2/chrome/chromium/src/out_chromecast_korlan/release'
ninja: error: gen/chromecast/internal/build/ota/iot/iot_dock_add_to_ota_stamp.d: depfile mentions '../../../../out/target/product/korlan/obj/NOTICE_FILES/src/system/chrome/bin/standalone_mojo_broker.txt' as an output, but no such output was declared
# 解决
cd /mnt/fileroot/shengken.lin/workspace/google_source/eureka-v2/chrome/chromium/src/out_chromecast_korlan/release/gen/chromecast/internal/build/ota/iot
mv iot_dock_add_to_ota_stamp.d iot_dock_add_to_ota_stamp.d-bak
# 这个问题和Acquiring ninja lock没有关系，这些是print打印出来的，这是因为iot_dock_add_to_ota_stamp.d 这个文件的原因，打ota包的时候生成的，这个文件会去standalone_mojo_broker.txt 检索对应的网址然后去做一些版本相关的检测工作吧（具体没研究），版本对不上就会出错，问题就出在一次打ota包之后生成了这个文件，下一次打包并不会重新生成新的，我觉得这是一个bug，应该每次编译ota包都要去重新生成一个最新的。所以我将 iot_dock_add_to_ota_stamp.d 这个文件删掉就OK了。这问题太诡异了，需要记一下。
# 而且，就算重新repo sync 也不会去更新这个文件，所以就算 repo sync ，甚至 repo forall -c 'git clean -f -d' 清除所有中间缓冲都不会起作用
rm  ./chromium/src/out_chromecast_korlan/release/gen/chromecast/internal/build/ota/iot/iot_dock_add_to_ota_stamp.d

# 再打 ota 包
# 编译出来的ota包在：out/target/product/korlan/korlan-ota-eng.shengken.lin.zip
```

## Koraln板子和芯片型号

- u-boot

> - u-boot/arch/arm/dts/meson-a1-a113l-korlan.dtsi
> - u-boot/arch/arm/mach-meson/board-common.c
> - arch/arm/mach-meson/

## Korlan 拨码快关

<img src="https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/korlan拨码开关.4t3eqr2yphu0.webp" style="zoom: 25%;" />

##  korlan 设置USB模式

```sh
#进入板子
# 设置 usb 为 host 模式
fts -s usb_controller_type  host
# 查看
fts -g usb_controller_type
# reboot 设置需要重启
# 查看
cat /proc/fts 
# 清空
#fts -i
# 或者 （设置 usb 为 host 模式）
echo 1 > /sys/kernel/debug/usb_mode/mode  

# 查看模式
device mode
	# cat /sys/kernel/debug/usb_mode/mode
	usb_mode: device
host mode
    # cat /sys/kernel/debug/usb_mode/mode
    usb_mode: host
    
cat /proc/fts
bootloader.command=boot-factory
enable_ethernet=dhcp
fts -g bootloader.command    # 查看
fts -s bootloader.command    # 设置 bootloader.command 为空
fts -s bootloader.command boot-factory # 设置 bootloader.command 为 boot-factory

```

## 查看和设置 fts 的值

```sh
# fts 实际上是 key-value 形式

# 设置
fts -s enable_ethernet dhcp
# 查看
fts -g "enable_ethernet"
```

## 打开uboot log 和设置bootdelay时间

```sh
board/amlogic/defconfigs/a1_korlan_b1_defconfig
@@ -10,7 +10,7 @@ CONFIG_DEBUG_UART_BASE=0xfe001c00
 CONFIG_DEBUG_UART_CLOCK=24000000
 CONFIG_DEBUG_UART=y
 CONFIG_OF_BOARD_SETUP=y
-CONFIG_BOOTDELAY=-2
+CONFIG_BOOTDELAY=2
 CONFIG_BOOTCOMMAND="run storeboot"
 CONFIG_BOARD_LATE_INIT=y
 # CONFIG_DISPLAY_CPUINFO is not set
@@ -103,7 +103,7 @@ CONFIG_LZ4=y
 CONFIG_NAND_FTS=y
 CONFIG_CMD_REBOOT=y
 CONFIG_CMD_FACTORY_BOOT=y
-CONFIG_LOGLEVEL=4
-CONFIG_SPL_LOGLEVEL=4
-CONFIG_TPL_LOGLEVEL=4
+CONFIG_LOGLEVEL=7
+CONFIG_SPL_LOGLEVEL=7
+CONFIG_TPL_LOGLEVEL=7
 CONFIG_CMD_USB_MODE=y
```

## korlan 出现 cache 分区挂载不起来

```sh
 busybox cat /sbin/check_and_mount_ubifs.sh 

/sbin/ubiattach /dev/ubi_ctrl -m 7 -d 7 -b 20

/sbin/ubimkvol /dev/ubi7 -m -N cache


mount -t ubifs ubi7:cache /data/ -o noexec,rw,nosuid,nodev,noatime;
```

## audio工具

### arecord、aplay、amixer

> 上传音频数据 adb push .\the-stars-48k-60s.wav /data/

#### arecord与aplay

```sh
arecord  -l  # 查询 linux 系统下设备声卡信息

arecord -D hw:0,0 -r 16000 -c 1 -f S16_LE test.wav  # 录制音频

Recording WAVE 'test.wav' : Signed 16 bit Little Endian, Rate 16000 Hz, Mono
^CAborted by signal Interrupt...  # 这里使用Ctrl+c 结束了录制

aplay -l # 查看播放设备
aplay -Dhw:0,0 /data/the-stars-48k-60s.wav   # 播放音频
```


#### amixer

- amixer controls 用于查看音频系统提供的操作接口
- amixer contents 用于查看接口配置参数
- amixer cget + 接口函数
- amixer cset + 接口函数 + 设置值

```sh
dmesg  -n 8   # 开 log
amixer cget numid=2       # 查看音量
amixer cset numid=2 150   # 修改音量
amixer cset numid=3  on
amixer cset numid=5 on 
# 或者
amixer cset numid=2,iface=MIXER,name='tas5805 Digital Volume' 150

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav

# 强制启动和关闭tdm_bridge
echo 0 > /sys/module/u_audio/parameters/free_run   
echo 1 > /sys/module/u_audio/parameters/free_run     #启动

echo 0xfe0501c0 10 > /sys/kernel/debug/aml_reg/dump
echo  0xfe050540 28 > /sys/kernel/debug/aml_reg/dump
cat /sys/kernel/debug/aml_reg/dump 

 echo 0 > /sys/module/u_audio/parameters/free_run  & aplay -Dhw:0,0 /data/the-stars-48k-60s.wav & echo 1 > /sys/module/u_audio/parameters/free_run 
```

### ubuntu 测试

```sh
# 查看所有 usb 设备
lsusb

# ssh 连接 ubuntu
ssh amlogic@10.28.39.83    # 1233456
# scp 文件
scp .\the-stars-48k-60s.wav amlogic@10.28.39.83:~/Desktop/lsken00
# 在测试中选 korlan 输出
```

----

# Spencer

> 波特率：921600

## sync spencer

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


## Build Spencer-SDK

### Bootloader

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

### Kernel

```sh
cd kernel
./build_kernel.sh spencer-p2 ./../../chrome
```

### module NN

```sh
# 用6.4.9分支
cd verisilicon
./build_ml.sh arm64 spencer-p2 ./../../chrome
cd -

# 如果遇到问题
# make: *** [makefile.linux:305: /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon/compiler/libGLSLC] Error 2
# 需要清理 
git clean -d -fx ./

# 如果有问题可以尝试下面方法
# 修改编译成静态库
verisilicon/build_ml.sh
304   BUILD_OPTION_gcdSTATIC_LINK=0  


vim ./acuity-ovxlib-dev/build_vx.sh
 81   BUILD_OPTION_gcdSTATIC_LINK=0
 82   BUILD_OPTION_STATIC_LINK=0

# 回退kernel
cd kernel
spencer-master 分支
git reset --hard 227d320dcdc40efd6ece0b58e0a8ddecb85b32b3
```

### 在DSP上编译freerots

```sh
# 修改代码： demos/amlogic/xtensa_hifi4/c2_spencer_flatbuftest_hifi4a/boot/startdsp.c
# 修改编译脚本只需要编译的
vim freertos/build_hifi_tests.sh  
# tests=$(find demos/amlogic/xtensa_hifi4/ -mindepth 1 -maxdepth 1 -type d -name "c2_spencer_flatbuftest_hifi4a")
# 这个目录下查看只编译一个： workspace\google_source\eureka\spencer-sdk\freertos\demos\amlogic\xtensa_hifi4

bash build_hifi_tests.sh debug 
# ./build_rtos.sh spencer-p2 ./../../chrome release --skip-dsp-build

Z:\workspace\google_source\eureka\spencer-sdk\freertos\hifi_tests> adb push .\c2_spencer_flatbuftest_hifi4a.bin /data/

# 到板子上
cp /data/c2_spencer_flatbuftest_hifi4a.bin /system/lib/firmware/dspboot.bin 
cp /data/c2_spencer_flatbuftest_hifi4a.bin /lib/firmware/dspboot.bin 
sync

# Run the test
# 1. -s                 : stop dsp
# 2. -r                 : reset dsp
# 3. -l --firmware=XXXX : reload dsp
# 4. -S                 : start dsp
dsp_util --dsp=hifi4a -s
dsp_util --dsp=hifi4a -r
dsp_util --dsp=hifi4a --firmware=dspboot.bin -l
dsp_util --dsp=hifi4a -S

# 查看结果
cat /sys/kernel/debug/hifi4frtos/hifi4

```

## 签名Spencer

> Notes: 首先需要先获取到pdk编译脚本，这里以 spencer-p2 为例

### 签名u-boot

```sh
cd chrome/pdk
# 签名会用到linux-x86的这些文件
# chrome$ tree out/host/
# out/host/
# └── linux-x86
#     └── bin
#         ├── kernel_iv.bin
#         ├── kernel_iv.txt
#         ├── mkbootimg
#         ├── pem_extract_pubkey.py
#         ├── sign-boot-g12a-dev.sh
#         └── sign-boot-g12a.sh

# 编译签名uboot
cd pdk
./create-uboot.sh -b  spencer-p2
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/spencer/upgrade
```

### 签名kernel

#### 获取生成ramdisk

下载最新的 ramdisk

> https://console.cloud.google.com/storage/browser/_details/cast-partner-amlogic-internal/internal/master/spencer-eng/314706/factory/spencer-fct-spencer-p2-314706.zip;tab=live_object

解压后将 fct_boot.img 拷贝到 chrome/pdk/unpack_boot 目录下

> 现在一般不下载 factory-boot , 下载 boot.img
>
> 直接下载 spencer-eng-ota 可能会出现 分区空间不足问题，需要下载对应版本的ota包，比如spencer-ota-spencer-p2-319922

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk/unpack_boot
mv boot.img spencer-boot.img
./unpack_boot.sh ./spencer-boot.img ./spencer-out_unpack unpack_boot    ## 注意修改脚本路径
cp ramdisk.img.xz ../../out/target/product/spencer/boot_unpack/ramdisk.img

## /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
./build-bootimg.sh -b spencer-p2
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/spencer/upgrade
```

## spencer烧录

```sh
cmd: adnl devices #确认已经进入烧录模式

# 强制进入烧录模式
adnl.exe  Download u-boot.signed.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F  u-boot.signed.bin

# 如果是正常启动 reboot update
adnl.exe oem "store init 1"
adnl.exe oem "mmc dev 1"

# 如果不单独编译dts这个可以不用执行，因为 dtb 已经打包到 u-boot.signed.bin
# adnl.exe Partition -M mem -P 0x1000000 -F spencer-p2.dtb
# adnl.exe oem "emmc part_write 0x1000000"

adnl.exe  Partition -M mem -P 0x2000000 -F u-boot.signed.bin
adnl.exe oem "store boot_write bootloader 0x2000000 0x1ffe00"


adnl.exe Partition -P tpl_a  -F tpl.signed.bin
adnl.exe Partition -P tpl_b  -F tpl.signed.bin
adnl reboot

adnl.exe Partition -P boot_a  -F boot.img
adnl.exe Partition -P boot_b  -F boot.img
adnl.exe Partition -P misc  -F misc.img
adnl.exe Partition -P system_a -F system.img
#adnl.exe Partition -P system_b  -F fct_boot.img  # 工厂boot烧录到system_b分区，这时不用烧录 system.img
# adnl.exe oem "enable_factory_boot"   # adnl.exe oem "disable_factory_boot" 
# 关闭工厂模式
# adnl.exe oem "store erase fts  0 0"
adnl.exe oem "reset" 

# 下载的ota
cat bl2.bin tpl.bin > u-boot.bin
adnl.exe Download bl2.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F u-boot.bin

# reboot update
adnl.exe oem "store init 1"
adnl.exe oem "mmc dev 1"
adnl.exe partition -M mem -P 0x2000000 -F bl2.bin
adnl.exe cmd "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a -F tpl.bin
adnl.exe Partition -P tpl_b -F tpl.bin
adnl.exe Partition -P misc -F misc.img
adnl.exe Partition -P boot_a -F boot.img
adnl.exe Partition -P boot_b -F boot.img
adnl.exe Partition -P system_a -F system.img
adnl reboot
```


## 编译 spencer-ota 

**参考**： https://confluence.amlogic.com/display/SW/6.+Spencer+OTA+Repacked

### Replace bootloader

下载 otatools 和 spencer-target_files 两个 zip 文件

`[下载地址](https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/spencer-eng/315654?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)`

- otatools

```sh
mkdir spencer-315654

cd spencer-315654

spencer-315654/spencer-otatools$ unzip  otatools.zip 
# 直接使用下载的 otatools 进行打包，不要用拷贝的方式
```

- missing-binary

下载 [missing-binary.zip](https://confluence.amlogic.com/download/attachments/180725736/missing-binary.zip?version=2&modificationDate=1651397450635&api=v2)

替换掉上面下载的 otatools 里面的文件

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/spencer-315654
mkdir missing-binary && mv missing-binary.zip missing-binary
unzip -o missing-binary.zip

#cd otatools
cp spencer-315654/missing-binary/make_ext4fs  build/bin/
cp spencer-315654/missing-binary/mkbootfs  build/bin/
cp spencer-315654/missing-binary/veritysetup  build/bin/

cp spencer-315654/missing-binary/signapk.jar ./build/framework/
cp spencer-315654/missing-binary/dumpkey.jar ./build/framework/

# 不需要替换
# cp spencer-315654/missing-binary/dumpkey.jar ./out/host/linux-x86/framework/
# cp spencer-315654/missing-binary/signapk.jar ./out/host/linux-x86/framework/

chmod 755 ./build/bin/make_ext4fs ./build/bin/mkbootfs ./build/bin/veritysetup 
```

- spencer-target_files

```sh
mkdir spencer-target_files && cd spencer-target_files
unzip spencer-target_files.zip

# 设置环境变量
export PATH=/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/build/bin/:$PATH
```

- 编译 u-boot 和 kernel

```sh
cd spencer-sdk

# 编译bootloader
cd bl2 && ./build_bl2.sh spencer-p2
cd bl31 && ./build_bl31.sh spencer-p2 
cd bl32 && ./build_bl32.sh spencer-p2
cd u-boot && ./build_uboot.sh spencer-p2 ../chrome/
# 编译出来的文件在： ll -t vendor/amlogic/spencer/prebuilt/bootloader/

# 编译kernel 和 modules
cd kernel && ./build_kernel.sh spencer-p2 ../../chrome/
# 编译出来的文件在：ll -t vendor/amlogic/spencer/prebuilt/kernel/
cd verisilicon && ./build_ml.sh arm64 spencer-p2 ../../chrome/  
# 编译出来的文件在： ll -t vendor/amlogic/spencer/prebuilt/kernel/modules/
```

- 拷贝和打包zip

```sh
# bootloader
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/spencer-315654/spencer-target_files
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/aml_ddr.fw BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl2_new.bin.spencer-p2 BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl31.img.spencer-p2  BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl32.img.spencer-p2  BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl33.bin.spencer-p2  BOOT/bootloader/

zip -r ./spencer-target_files.zip -f ./BOOT/bootloader

# kernel

# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/spencer-315654/spencer-target_files
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/kernel/modules/*spencer-p2.ko ./BOOT/RAMDISK/lib/kernel/modules/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/kernel/kernel.spencer.gz-dtb.spencer-p2 ./BOOT/RAMDISK/lib/kernel/kernel-spencer-p2 

zip -r ./spencer-target_files.zip -f ./BOOT/RAMDISK/lib/


cd chrome

mv out/host/linux-x86/bin out/host/linux-x86/bin1

# ./vendor/amlogic/build/tools/releasetools/ota_from_target_files -v --board spencer-p2 ./spencer-315654/spencer-target_files/spencer-target_files.zip ./spencer-315654/replace-bootloader-kernel-ota.zip
# 这里直接使用 otatools 下的 ota_from_target_files 打包
otatools/bin/ota_from_target_files -v --board spencer-p2 ./spencer-315654/spencer-target_files/spencer-target_files.zip ${your_path}/eureka/replace-ota/spencer-replace-ota/replace-bootloader-kernel-ota.zip

mv out/host/linux-x86/bin1 out/host/linux-x86/bin
```

- 拷贝解压烧录

解压

```sh
unzip replace-bootloader-kernel-ota.zip 
cat bl2.bin tpl.bin > u-boot.bin
```


----

# Venus

> venus 和 spencer 是公用的，都是 spencer-master 分支

## 编译 venus

```sh
# build without "release"，Default compilation option will enable logs. 

cd ~/eureka/venus-sdk/
 
cd bl2
./build_bl2.sh venus-p2 release
cd -
 
cd bl31
./build_bl31.sh venus-p2 release
cd -
 
cd bl32
./build_bl32.sh venus-p2 release
cd -
 
cd u-boot
./build_uboot.sh venus-p2 ./../../chrome release
cd -

ce kernel
./build_kernel.sh venus-p2 ./../../chrome

# git clean -d -fx ./
cd verisilicon
./build_ml.sh arm64 venus-p2 ./../../chrome

cd freertos
# vim freertos/build_hifi_tests.sh 
# 这个目录下查看只编译一个： workspace\google_source\eureka\venus-sdk\freertos\demos\amlogic\xtensa_hifi4
# ./build_rtos.sh venus-p2 ./../../chrome release --skip-dsp-build
# bash build_hifi_tests.sh debug 
cd -
# 输出目录：out_dsp/dspboot.bin

# 运行dsp
adb push dspboot.bin 到/system/lib/firmware/
```



## 烧录venus

```sh
Normal upgrade:
reboot update

cmd: adnl devices #确认已经进入烧录模式

# 强制进入烧录模式
adnl.exe  Download u-boot.signed.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F  u-boot.signed.bin

# 如果是正常启动 reboot update

:: step 1
adnl.exe oem "store init 1"
adnl.exe oem "mmc dev 1"

:: step 2
adnl.exe Partition -M mem -P 0x2000000 -F u-boot.signed.bin
adnl.exe oem "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a  -F tpl.signed.bin
adnl.exe Partition -P tpl_b  -F tpl.signed.bin
# adnl reboot

adnl.exe Partition -P boot_a -F boot.img
adnl.exe Partition -P boot_b -F boot.img

adnl.exe Partition -P system_b -F boot.venus-p2.img
# adnl.exe Partition -P boot_a  -F boot.venus-p2.img
# adnl.exe Partition -P boot_b  -F boot.venus-p2.img

adnl.exe oem "enable_factory_boot"   # adnl.exe oem "disable_factory_boot" 
# adnl.exe oem "store erase fts  0 0"





----

# adnl.exe partition -M mem -P 0x2000000 -F bl2.signed.bin
# adnl.exe oem "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a -F tpl.signed.bin
adnl.exe Partition -P tpl_b -F tpl.signed.bin

:: step 3
adnl.exe Partition -P misc -F misc.img

:: step 4
adnl.exe Partition -P boot_a -F boot.img
adnl.exe Partition -P boot_b -F boot.img

:: step 5
adnl.exe Partition -P system_a -F system.img

adnl.exe oem "enable_factory_boot"

adnl.exe reboot
```

## 无法进入烧录模式

```sh
fts -s bootloader.command  # 设置bootloader命令
fts -i  #清除工厂模式

start usb_update; reboot update; # 进入烧录模式

# 或者
reboot bootloader;   # 进入uboot
adnl   # 进入烧录模式
```



---

# GQ

## GQ Sync

> repo init -u  https://eureka-partner.googlesource.com/amlogic/manifest -b quartz-master  -m combined_sdk.xml
>
> repo init -u https://eureka-partner.googlesource.com/amlogic/freertos -b quartz-master  -m combined_sdk.xml
>
> repo sync

或者从 Spencer-sdk 拷贝过来并切换分支

```sh
cp spencer-sdk GQNQ-sdk -rfL 
```

**切换分支** ： `bl31 bl32 uboot kernel` 都是 quartz-master，bl2 是 quartz-master-v2



## GQ编译和签名


### 编译Bootloader (bl2 + bl31 + bl32 + u-boot)

> 若不加release参数，编译默认打开bootloader日志

```sh
cd bl2
./build_bl2.sh gq-b3 release
cd -


cd bl31
./build_bl31.sh gq-b3 release
cd -

cd bl32
./build_bl32.sh gq-b3 release
cd -

# 可能会报错： Fatal error: script ./build_bl32.sh aborting at line 149, command "scripts/pack_kpub.py --rsk=keys/root_rsa_pub_key.pem --rek=keys/root_aes_key.bin --in=out/arm-plat-meson/core/bl32.img --out=out/bl32.img" returned 1

# 需要修改Python版本
vi scripts/pack_kpub.py
#!/usr/bin/env python2   第一行

cd u-boot
./build_uboot.sh gq-b3 ./../../chrome release
cd -
```

###  编译arm RTOS

```sh
cd freertos
./build_rtos.sh gq-b3 ./../../chrome release --skip-dsp-build
cd -
```

### 编译Kernel

```sh
cd kernel
./build_kernel.sh gq-b3 ./../../chrome 
cd -
```

> 注意：如果是从spencer-sdk拷贝过来的可能会报下面的错误：
>
> `Fatal error: script ./build_kernel.sh aborting at line 54, command "make CLANG_TRIPLE=$1 CC=$cc_clang CROSS_COMPILE=$1 ARCH=$3 -j$2 $4 CONFIG_DEBUG_SECTION_MISMATCH=y" returned 2`
>
> 解决方法：
>
> cd dhd-driver
>
> 切换到 dhd_1.579.77.41.x 这个分支
>
> git checkout -t  remotes/origin/dhd_1.579.77.41.x

### 编译isp module

```sh
cd lloyd-isp
./build_isp.sh gq-b3 ./../../chrome 
cd -
```



### 编译NN module

```sh
cd verisilicon
./build_ml.sh arm64 gq-b3 ./../../chrome 
cd -
```

### 全部编译 build_all

```shell
cd /GQNQ-sdk
bash ./sdk/build_scripts/build_all.sh ../chrome/  gq-b3
# bash ./sdk/build_scripts/build_all.sh ../chrome/  gq    # 我的服务器已经脚本改成只有gq
```

### 签名

#### 签名uboot

```sh
cd pdk
./create-uboot.sh -b  gq-b3
```

#### 签名kernel

```#### dsh
# 制作好ramdisk
# cd mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/gq
mkdir boot_unpack
# 拷贝ramdisk.img进去
cd /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
./build-bootimg.sh -b  gq-b3
```

#### 签名rots

```sh
# 编译出来的镜像文件在 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/rtos/rtos-uImage.gq-b3
cd pdk
./sign_rtos.sh -i /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/rtos/rtos-uImage.gq-b3 -b gq-b3
```

## GQ烧录

```sh
# z/workspace/google_source/eureka/chrome/out/target/product/gq/upgrade

# 强制进入烧录模式， 只需要长按复位键即可
adnl.exe Download bl2.signed.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F u-boot.signed.bin

# 正常启动进入烧录模式
start usb_update; reboot update;

adnl.exe oem store init 1
adnl.exe oem mmc dev 1

adnl.exe partition -M mem -P 0x2000000 -F bl2.signed.bin
adnl.exe cmd "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a -F tpl.signed.bin
adnl.exe Partition -P tpl_b -F tpl.signed.bin

adnl.exe Partition -P misc -F misc.img

adnl.exe Partition -P boot_a -F boot.img
adnl.exe Partition -P boot_b -F boot.img

adnl.exe partition -P rtos_a -F rtos.img
adnl.exe partition -P rtos_b -F rtos.img

adnl.exe Partition -P system_a -F system.img

adnl.exe oem "reset"
```

## 制作ramdisk

在这里找到最新的 gq-eng下载 :  https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/gq-eng

- **使用 boot.img 解压**

```sh
# 拷贝下载好的  boot.img 到
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk/unpack_boot
mv boot.img gq-boot.img
mkdir ./gq-out_unpack
./unpackbootimg -i ./gq-boot.img -o ./gq-out_unpack
cp ./gq-out_unpack/gq-boot.img-ramdisk.gz ../../out/target/product/gq/boot_unpack/ramdisk.img
```

- 使用fct_boot.img解压

如果 boot.img解压出 ramdisk 有问题，可能需要使用 factory 来解包出 ramdisk.img

[下载地址](https://console.cloud.google.com/storage/browser/_details/cast-partner-amlogic-internal/internal/master/gq-eng/317444/factory/gq-fct-gq-b3-317444.zip;tab=live_object)

```sh
# 拷贝下载好的 fct_boot.img到
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk/unpack_boot
mv fct_boot.img gq-fct_boot.img
mkdir gq-boot_unpack
./unpackbootimg -i ./gq-fct_boot.img -o ./gq-boot_unpack
cp ./gq-boot_unpack/gq-fct_boot.img-ramdisk.gz ../../out/target/product/gq/boot_unpack/ramdisk.img
```

> 接下来可以签名kernel并烧录

## NN模型转换和测试

参考我的总结：https://docs.google.com/document/d/1JcOd5uLQAqdS8EtGSqvew1or_HZnDBiNP2-DE3C9zQ0/edit?usp=sharing



-----

# Elaine

## Sync elaine

```sh
mkdir elaine-sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b elaine -m combined_sdk.xml
repo sync

# 提交代码
git add
git commit -s    # 第一次
git commit --amend --no-verify  # 第二次
git push eureka-partner HEAD:refs/for/elaine
```

## 编译 elaine

- 整体编译

```sh
./sdk/build_scripts/build_all.sh ../chrome elaine
```

- 分别编译

```sh
cd bl2
./build_bl2.sh elaine-b3 release
cd -

cd bl31
./build_bl31.sh elaine-b3 release
cd -

cd bl32
./build_bl32.sh elaine-b3 release
cd -

cd u-boot
./build_uboot.sh elaine-b3 ./../../chrome release
cd -

cd kernel
./build_kernel.sh elaine-b3 ./../../chrome 
cd -


cd mali-driver
./build_mali.sh elaine-b3 ../../chrome/
cd -
# 将 mali_kbase.ko push 到 ./system/lib/modules/mali.ko 
# 需要使用网络 adb
adb connect ip:5555

加载 mali.ko 的脚本 /usr/bin/insert_modules.sh
```

## 制作Elaine-ramdisk

```sh
# 拷贝下载好的  boot.img 到
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk/unpack_boot
mv boot.img elaine-boot.img
./unpack_boot.sh ./elaine-boot.img ./elaine-out_unpack unpack_boot    ## 注意修改脚本路径

mkdir -p ../../out/target/product/elaine/boot_unpack
cp ./elaine-out_unpack/ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/elaine/boot_unpack/ramdisk.img

# 签名
## /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
./build-bootimg.sh -b elaine-b3
# 输出：/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/spencer/upgrade
```

## 签名elaine

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
# 签名 u-boot
./create-uboot.sh -b  elaine-b3

# kernel
## /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
./build-bootimg.sh -b elaine-b3
# 输出：/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/elaine/upgrade
```



## 烧录 elaine

下载 update.exe 

https://wiki-china.amlogic.com/index.php?title=Amlogic_Tools/Update%E5%91%BD%E4%BB%A4

>  在板子的linux控制台下 reboot update, 或者在uboot控制下run update
>
>  启动windows控制台，使用update 命令

```sh
update.exe write bl2.signed.bin 0xfffa0000

update.exe bl2_boot u-boot.signed.bin

update.exe  bulkcmd "store init"
update.exe  bulkcmd "mmc dev 1"

# 正常进入烧录

update.exe partition bootloader bl2.signed.bin
update.exe partition tpl_a tpl.signed.bin
update.exe partition tpl_b tpl.signed.bin

update.exe partition boot_a boot.img
update.exe partition boot_b boot.img
update.exe partition system_a system.img

update bulkcmd "reset"

# google下载的ota
update.exe write bl2.bin 0xfffa0000
update.exe run  0xfffa0000

cat bl2.bin tpl.bin > u-boot.bin
update.exe bl2_boot u-boot.bin

update.exe  bulkcmd "store init"
update.exe  bulkcmd "mmc dev 1"

# 正常进入烧录
update.exe partition bootloader bl2.bin
update.exe partition tpl_a tpl.bin
update.exe partition tpl_b tpl.bin

update.exe partition boot_a boot.img
update.exe partition boot_b boot.img
update.exe partition system_a system.img

update bulkcmd "reset"
```

## adb无法使用-修改usb控制器模式

```sh
vim kernel/arch/arm64/boot/dts/amlogic/elaine-b3.dts 
1405     /* 1: host only, 2: device only, 3: OTG */
1406     /*controller-type = <1>;*/
1407     controller-type = <3>;   

# 进入kernel执行
#! /sbin/busybox sh
mount -t configfs configfs /sys/kernel/config
mkdir /sys/kernel/config/usb_gadget/amlogic
echo 0x18D1 > /sys/kernel/config/usb_gadget/amlogic/idVendor
echo 0x4e26 > /sys/kernel/config/usb_gadget/amlogic/idProduct
mkdir /sys/kernel/config/usb_gadget/amlogic/strings/0x409
echo '0123456789ABCDEF' > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/serialnumber
echo amlogic > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/manufacturer
echo newman > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/product
mkdir /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1
mkdir /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409
echo adb > /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409/configuration
mkdir /sys/kernel/config/usb_gadget/amlogic/functions/ffs.adb
mkdir /dev/usb-ffs
mkdir /dev/usb-ffs/adb
mount -t functionfs adb /dev/usb-ffs/adb
stop adbd
ln -s /sys/kernel/config/usb_gadget/amlogic/functions/ffs.adb /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/ffs.adb
start adbd
/bin/sleep 2
echo ff400000.dwc2_a > /sys/kernel/config/usb_gadget/amlogic/UDC
```

---



# Chrome

## 单独编译一个模块

- 比如 adb

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/adb
source build/envsetup.sh 
lunch
cd system/core/adb
mma PARTNER_BUILD=true
```

- 比如 nandread

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/toolbox
source build/envsetup.sh 
lunch
cd system/core/toolbox
mma PARTNER_BUILD=true
```

## ramdisk 路径

```
vendor/amlogic/korlan/
```

# VSI-NN module测试

总结文档：https://docs.google.com/document/d/1JcOd5uLQAqdS8EtGSqvew1or_HZnDBiNP2-DE3C9zQ0/edit

- 1.Get NN Driver

> eg: Verisilicon_SW_Unified_Driver_6.4.9_Amlogic_20211231.tgz

> tar -zxf and copy 到 spencer-sdk/verisilicon，然后 cherry pick https://eureka-partner.googlesource.com/verisilicon-sdk （全部一个个cherry pick）

## 在 ubuntu 上构建 NN 模型

(1) Vivante_acuity_toolkit_binary_6.3.1_20211229_ubuntu18.04.tgz

(2) Copy tgz to Ubuntu

(3) Start convert NN

(4) Build and get bin_r

(5) test NN model in spencer-p2

```sh
# ~/NN/649/actool_6.3.1/acuity-toolkit-binary-6.3.1/google_test_mode/ssd_small_multiout
# 编译 ssd_small_multiout
$ bash step1.sh ssd_small_multiout
$ bash step2.sh ssd_small_multiout
# rm ssd_small_multiout_be/ -rf
# rm ssd_small_multiout.data 
# rm ssd_small_multiout.quantize 
# rm tflite.export.data 
# rm ssd_small_multiout.json 
# rm iter_0_output*

bash step1.sh ssd_small_multiout
# 参考上面的doc修改
vim ssd_small_multiout.json
vim ssd_small_multiout_inputmeta.yml

bash step2.sh ssd_small_multiout
vim ../ssd_big_multiout/ssd_big_multiout_04_be.sh

bash step3.sh ssd_small_multiout
bash step4_inference.sh ssd_small_multiout
```

### 选择对应的板子

```sh
# /mnt/fileroot/shengken.lin/workspace/a5_buildroot/hardware/aml-4.9/npu/nanoq/hal/inc/gc_vsim_configs.h  
# 参考上面的文件修改这个值
# ssd_big_multiout/ssd_big_multiout_04_be.sh
https://docs.google.com/document/d/1JcOd5uLQAqdS8EtGSqvew1or_HZnDBiNP2-DE3C9zQ0/edit# VIPNANOQI_PID0XA1
--optimize VIP9000NANOS_PID0X1000000E  #av400
--optimize VIP9000NANODI_PID0XBE   #c2
```

### linux打开当前文件夹

```sh
nautilus .
```



## 编译模型

```sh
# 6.4.2 模型测试需要退 verisilicon 回到 a3a7bfc470082aad8dd4fade29fabddb7deb850b 这个 commit

# cp  /mnt/fileroot/yuegui.he/c2/amlogic_sdk/alexnet_caffe_be/build_vx.sh spencer-sdk/
# eureka/spencer-sdk/alexnet_caffe_be
vim makefile.linux 
# change 114 line 
114 TARGET_NAME = alexnet_caffe_be # 编译出来的文件名

# 设置模型输出为txt文件
# change vnn_post_process.c 46 line
vim vnn_post_process.c 
   46 //        vsi_nn_SaveTensorToBinary(graph, tensor, filename);
   47         vsi_nn_SaveTensorToTextByFp32(graph, tensor, filename, "\n");
or
   47        vsi_nn_SaveTensorToTextByFp32( graph, tensor, filename, NULL );

# 编译
spencer-sdk/alexnet_caffe_be$ ./build_vx.sh 

```

## push 相关库

```
adb.exe push .\build\sdk\drivers\. /usr/lib/

# 如果push到其他目录需要设置环境变量
export LD_LIBRARY_PATH=/data:$LD_LIBRARY_PATH  # spencer

# 声明环境变量 打印更多信息
export VIV_VX_DEBUG_LEVEL=1
```



## 测试模型

```sh
Z:\workspace\google_source\eureka\spencer-sdk\verisilicon> adb.exe push .\build\sdk\drivers\ /lib/
Z:\workspace\google_source\eureka\spencer-sdk\verisilicon> adb.exe push .\galcore.ko /data

rmmod galcore
insmod ./data/galcore.ko showArgs=1

Z:\workspace\google_source\eureka\spencer-sdk> adb.exe push .\alexnet_caffe_be\data\space_shuttle.jpg /data/alexnet_caffe_be

Z:\workspace\google_source\eureka\spencer-sdk> adb.exe push .\alexnet_caffe_be\alexnet_caffe_be.nb /alexnet_caffe_be

Z:\workspace\google_source\eureka\spencer-sdk> adb.exe push .\alexnet_caffe_be\bin_r\alexnet_caffe_be /data/alexnet_caffe_be
chmod /data/*

# 执行测试
/data/alexnet_caffe_be# chmod 777 *
./alexnet_caffe_be ./alexnet_caffe_be.nb space_shuttle.jpg
Create Neural Network: 75ms or 75138us
Verify...
Verify Graph: 1ms or 1242us
Start run graph [1] times...
Run the 1 time: 5.46ms or 5462.71us
vxProcessGraph execution time:
Total
5.54ms or 5542.29us
Average 5.54ms or 5542.29us
--- Top5 ---
812: 0.954590
404: 0.024567
895: 0.005264
908: 0.003252
565: 0.002954

# 如果想一直跑需要声明环境变量 （venus）
export VNN_LOOP_TIME=10000

# 声明环境变量 打印更多信息
export VIV_VX_DEBUG_LEVEL=1
export VIV_NN_LOGLEVEL=5
```

## 修改公版代码支持 NN

> 这里以 a5_av400 为例

```shell
# 需要修改的代码文件
vim hardware/aml-5.4/npu/nanoq/hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c 
vim spencer-sdk/verisilicon/hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c 
```

从 dts 中找到 NN 对应的 nn_power_version ，然后在代码  `spencer-sdk/verisilicon/hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c`  添加 

> 可以参考 NN-av400-arm64-verisilicon-6.4.11.2-gc_hal_kernel_platform_amlogic.patch 这个 patch

```c
// hardware/aml-5.4/npu/nanoq/hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c 
static const struct of_device_id galcore_dev_match[] = {
  {
    .compatible = "amlogic, galcore"  // 去 arm64/boot/dts/amlogic/a5_a113x2_av400_1g.dts 这里找到对应节点下的 compatible 值
  },
    { },
};
int gckPLATFORM_Init(struct platform_driver *pdrv, gcsPLATFORM **platform)
{       
    pdrv->driver.of_match_table = galcore_dev_match; //从上面复制下来
    *platform = &default_platform; 
    return 0; 
} 

//找到 dts kernel/aml-5.4/arch/arm64/boot/dts/amlogic/meson-a5.dtsi
	galcore {
		compatible = "amlogic, galcore";
		dev_name = "galcore";
		status = "okay";
		clocks = <&clkc CLKID_CTS_NNA_AXI_CLK>,
		      <&clkc CLKID_CTS_NNA_CORE_CLK>;
		clock-names = "cts_vipnanoq_axi_clk_composite",
		      "cts_vipnanoq_core_clk_composite";
		interrupts = <0 128 4>;
		interrupt-names = "galcore";
		power-domains = <&pwrdm PDID_A5_NNA>;
		reg = <0x0 0xfdb00000 0x0 0x40000
		      0x0 0xf7000000 0x0 0x200000
		      0x0 0xfe00c040 0x0 0x4
		      0x0 0xfe00c044 0x0 0x4
		      0x0 0xfe00c034 0x0 0x4
		      0X0 0xfe000220 0X0 0x4>;
		reg-names = "NN_REG","NN_SRAM","NN_MEM0",
		      "NN_MEM1","NN_RESET","NN_CLK";
		nn_power_version = <6>;   // 这个是最重要的
	};
```

# ramdisk.img 解包

## korlan的ramdisk

```sh
# 解压 korlan的ramdisk
file ramdisk.img
mv ramdisk.img ramdisk.img.xz
unxz ramdisk.img.xz
cpio -i -F ramdisk.img   #解压cpio

# 打包
find . |cpio -ov -H newc | xz -9  --check=crc32  > ../ramdisk.img
```

## spencer gq 的ramdisk

```sh
# 解压 gq / spencer 的 ramdisk
file gq-fct_boot.img-ramdisk.gz
cp gq-fct_boot.img-ramdisk.gz  ramdisk_out/ && cd ramdisk_out
mv gq-fct_boot.img-ramdisk.gz gq-fct_boot.img-ramdisk.lzo
lzop -d gq-fct_boot.img-ramdisk.lzo   #解压
mkdir out_target 
cp gq-fct_boot.img-ramdisk out_target/ && cd out_target/
file gq-fct_boot.img-ramdisk
cpio -i -F gq-fct_boot.img-ramdisk 

# 打包
cd out_target
find . |cpio -ov -H newc | lzop -9 > ../ramdisk.img
# 拷贝到签名名录并签名烧录
cp ramdisk.img /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/gq/boot_unpack/
```

# 芯片代称对应

- spencer/venus -- C2

- gq/nq -- C1

- korlan  -- A1

- newman -- G12B

- elaine -- SM1

# Sonos

## buildroot-openlinux

### 拉代码 openlinux

- 修改 git 邮箱：使用 amlogic 

- 关掉 depot_tools

```
cd sonos-openlinux
repo init -u ssh://android@source2.amlogic.com/sonos/platform/manifest -b buildroot-openlinux-202207-a113x2-av400-sbr -m buildroot-openlinux-202207-a113x2-av400-sbr.xml
repo sync
```

### 编译Sonos-A113x2

```sh
source setenv.sh 
# 选择板子 10. a5_av400_a6432_releas
make

make show-targets | grep aml-hifi-rtos-sdk
# 编译aml-hifi-rtos-sdk
# make aml-hifi-rtos-sdk-dirclean # 如果修改了 package 在output 下不生效就执行这个
make aml-hifi-rtos-sdk-rebuild

#编译 kernel
make linux-rebuild

# 编译 uboot
make uboot-rebuild
```

### Sonos 加载 dsp 的脚本

```sh
vim buildroot/package/amlogic/aml-hifi-rtos-sdk/S71_load_dspa
# output/a5_av400_a6432_release/target$ cat etc/init.d/S71_load_dspa
dsp_util --load --dsp hifi4a -f dspbootA.bin

# 默认 dspbootA.bin 存放的路径
/lib/firmware/dspbootA.bin
```

## A113D

### 拉代码 A113D 

> 参考： https://confluence.amlogic.com/display/SW/Sonos+project+summary

```sh
git config --global user.name "shengken.lin"
git config --global user.email "shengken.lin@amlogic.com"

cd sonos-sdk
repo init -u ssh://android@source2.amlogic.com/sonos/platform/manifest
repo sync

Kernel：
     ssh://android@source2.amlogic.com/sonos/kernel/common   branch：20180608-v4.9.99
uboot：
     ssh://android@source2.amlogic.com/sonos/uboot    branch： master
BL2：
     ssh://android@source2.amlogic.com/sonos/bl2    branch： master
signing tool:
     ssh://android@source2.amlogic.com/sonos/tools/signing
```

### 编译A113D 

```sh
# 拷贝 dl
cp ../sonos-openlinux/buildroot/dl/ ./buildroot/ -r
cp ../sonos-openlinux/multimedia/libplayer/ ./multimedia/ -r

source buildroot/build/setenv.sh
# 选择 1. mesonaxg_s400_32_release
make

# error， ubuntu 20 之后会报这个错
92 |  #error "Please port gnulib freadahead.c to your platform! Look at the definition of fflush, fread, ungetc on your system, then report this to bug-gnulib
# 解决
cd /mnt/fileroot/shengken.lin/workspace/sonos-sdk/output/mesonaxg_s400_32_release/build/host-m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
```

- 其他 error 解决：[参考这里](https://confluence.amlogic.com/pages/viewpage.action?pageId=231134131)

### 烧录s400

```
# 进入 uboot
up
```
