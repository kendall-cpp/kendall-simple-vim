
- [BuildRoot_A1 代码提交](#buildroot_a1-代码提交)
  - [提交kernel gerrit](#提交kernel-gerrit)
  - [提交uboot gerrit](#提交uboot-gerrit)
- [andl korlan烧录命令记录](#andl-korlan烧录命令记录)
- [Korlan项目](#korlan项目)
  - [代理](#代理)
  - [整体编译](#整体编译)
  - [单独编译u-boot和kernel](#单独编译u-boot和kernel)
    - [uboot](#uboot)
    - [kernel](#kernel)
    - [Google项目push pull](#google项目push-pull)
    - [整理成脚本编译](#整理成脚本编译)
- [Google项目板子和芯片相关型号](#google项目板子和芯片相关型号)
  - [ramdisk.img 解包](#ramdiskimg-解包)
  - [gpio xz 相关命令](#gpio-xz-相关命令)
- [arecord、aplay、amixer 使用](#arecordaplayamixer-使用)
  - [arecord与aplay](#arecord与aplay)
  - [amixer](#amixer)
    - [在 Ubuntu 下测试](#在-ubuntu-下测试)
- [打印 iomem 寄存器地址](#打印-iomem-寄存器地址)
- [spencer烧录命令](#spencer烧录命令)
- [芯片代称对应](#芯片代称对应)

-----

## BuildRoot_A1 代码提交

### 提交kernel gerrit


> - https://scgit.amlogic.com/#/admin/projects/kernel/common
> - Project
> - General
> - Project kernel/common
> - git clone ssh://shengken.lin@scgit.amlogic.com:29418/kernel/common

```sh
git config --global user.email "shengken.lin@amlogic.com"

git config --global user.name "shengken.lin"


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

- 提交查看：https://scgit.amlogic.com/#/dashboard/self

### 提交uboot gerrit


- 初次

git commit --amend

```
[Don't merge] Add a5_amlogictest bsp

PD#SWPL-89613

Problem:
U-boot environment preparationn

Solution:
Add a5_amlogictest bsp and finish compiling

Verify:
a5_av400
```

```sh
git config --local user.name "shengken.lin"
git config --local user.email "shengken.lin@amlogic.com"

git branch -a | grep amlogic-4.19-dev
git checkout -t remotes/amlogic/amlogic-4.19-dev  切换分支
git branch
# git add kendall
git status
git commit --amend -s    -s 代表添加当前用户,写注释
git push review HEAD:refs/for/amlogic-dev-2019
```

- 打 patch


```sh
git add arch/arm/dts/meson-a5-all32-amlogictest.dtsi
git add arch/arm/dts/meson-a5-av400.dtsi
git add board/amlogic/a5_amlogictest/a5_amlogictest.c
git add board/amlogic/a5_av400/a5_av400.c
git add cmd/amlogic/cmd_rpmb.c
git add common/Kconfig
git add drivers/mtd/nand/raw/aml_nand/nand_flash.c

git commit --amend -s --no-verify   忽略掉代码不规范错误
```

- 编写测试

```
[Don't merge] Change a5_amlogictest bsp

PD#SWPL-89613

Problem:
The hardware of the development board is nand unable to burn

Solution:
Change a5_amlogictest to nand

Verify:
a5_av400
```

- 提交

git push review HEAD:refs/for/amlogic-dev-2019

最终提交：https://scgit.amlogic.com/245893

----

## andl korlan烧录命令记录

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

## Korlan项目

> Baud rate 为 115200

### 代理

> 参考： https://confluence.amlogic.com/pages/viewpage.action?spaceKey=SW&title=0.+Get+the+google+source+code+access+-+Updated+2022

公司的代理

```
# 公司的
proxy = 10.78.20.250
proxy_type = http
proxy_port = 3128
# proxy_user = shengken.lin
# proxy_pass = New@345
proxy_rdns = True
```

- 设置 git

```sh
git config --global user.email shengken.lin@amlogic.corp-partner.google.com

git config --global user.name "shengken lin"

# 代理设置
git config --global http.proxy http://10.78.20.250:3128
git config --global https.proxy https://10.78.20.250:3128
```

### 整体编译

```sh
google_source/eureka/amlogic_sdk$ ./sdk/build_scripts/build_all.sh ../chrome korlan
```

### 单独编译u-boot和kernel

- 先将下载的 boot.img 拷贝到 unpack_boot_ramdisk_script 
- 编译 uboot
- 拷贝 ramdisk 到 `To_shengken_sign/korlan/`
- 编译 kernel
- 用 andl 工具烧录 `Z:\workspace\google_source\eureka\amlogic_sdk\To_shengken_sign\korlan\korlan-p2`

> reboot update -- 进入烧录模式

#### uboot

- 编译

```sh
$ cd /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/To_shengken_sign
$ ./main.sh ../../amlogic_sdk/ u-boot korlan p2 ../../chrome

# 或者
$ ./main.sh  /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/ u-boot korlan p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
```

- 烧录

```sh
# z/workspace/google_source/eureka/amloc_sdk/To_shengken_sign/korlan/korlan-p2
adnl.exe  Download u-boot.bin 0x10000  # 上电强制进入烧录模式
adnl.exe run
adnl.exe bl2_boot -F  u-boot.bin

adnl.exe oem "store init 1"
# reboot update 进入烧录模式
adnl.exe oem "store boot_erase bootloader"
adnl.exe Partition -P bootloader  -F  u-boot.bin
adnl.exe oem "reset"
```

**注意：** 每次Google 更新都需要拷贝 boot.img

[下载地址：](https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/korlan-eng/262831?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)

下载完之后

将 D:\KendallFile\GoogleHome\internal_master_korlan-eng_309703_korlan-ota-korlan-p2-309703\boot.img 拷贝到 Z:\workspace\google_source\eureka\amlogic_sdk\unpack_boot_ramdisk_script

然后再使用 bash unpack_boot.sh ./boot.img ./boot_out unpack_boot 进行打包，接着拷贝

cp ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/To_shengken_sign/korlan/ramdisk.img

#### kernel 

```sh
$ cd /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/To_shengken_sign
$ ./main.sh ../../amlogic_sdk/ kernel korlan p2 ../../chrome

或者
$ ./main.sh /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/ kernel korlan p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
```

Note: 生成的 u-boot.bin & boot-sign.img, 在 korlan/korlan-p2 下面


到 powerShell

```sh
#  Z:\workspace\google_source\eureka\amlogic_sdk\To_shengken_sign\korlan\korlan-p2>
adnl.exe oem "store erase boot 0 0"
adnl.exe Partition -P boot  -F ./boot-sign.img
adnl.exe oem "reset"  重启
```

#### Google项目push pull

```sh
git config --local user.name "Shengken Lin"
git config --local user.email shengken.lin@amlogic.corp-partner.google.com

# 设置代理 # 公司的
proxy = 10.78.20.250
proxy_type = http
proxy_port = 3128

vim ~/.gitconfig 

git remote -v
git pull eureka-partner korlan-master  # 新的


git add sound/soc/codecs/tas5825m.c

git commit -s --no-verify    # git commit --amend  --no-verify     #第二次 加changeID

git push eureka-partner HEAD:refs/for/korlan-master
```



#### 整理成脚本编译

- kendall-complie_uboot_kernel.sh u-boot 编译 u-boot
- kendall-unpack_boot_copyRamdisk.sh
- kendall-complie_uboot_kernel.sh kernel  编译 kernel

> 生成的文件在 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/To_shengken_sign/korlan/korlan-p2

- 烧录

reboot update 进入烧录模式

> 考妣 system.img 到 Z:\workspace\google_source\eureka\amlogic_sdk\To_shengken_sign\korlan\korlan-p2 这个目录下

```sh
adnl.exe  Download u-boot.bin 0x10000  # 上电强制进入烧录模式
adnl.exe run
adnl.exe bl2_boot -F  u-boot.bin

adnl.exe oem "store init 1"
# 一般从这开始
adnl.exe oem "store boot_erase bootloader"
adnl.exe oem "store erase boot 0 0"
adnl.exe oem "store erase system 0 0"
adnl.exe Partition -P bootloader  -F  u-boot.bin
adnl.exe Partition -P boot  -F boot-sign.img
adnl.exe Partition -P system  -F system.img
adnl.exe oem "reset"    #重启，强制上电需要断电重启
```

## Google项目板子和芯片相关型号

只需关注

- u-boot

> - u-boot/arch/arm/dts/meson-a1-a113l-korlan.dts
> - u-boot/arch/arm/mach-meson/board-common.c
> - arch/arm/mach-meson/a


### ramdisk.img 解包

### gpio xz 相关命令

```sh
mv ramdisk.img ramdisk.img.xz
unxz ramdisk.img.xz 
file ramdisk.img   # 查看文件类型
cpio -i -F ramdisk.img

打包 cpio 和 xz
find x* | cpio -o > ramdisk.img.cpio
xz -k   解压

如果是点 gz 结尾
gunzip rootfs.cpio.gz 
```

- xz 命令

```
xz -d  env.xz   解压
unxz   env.xz   解压

-z, --compress      强制压缩
-d, --decompress    强制解压
-t, --test          测试压缩文件完整性
-l, --list          列出有关文件的信息
-k, --keep          保留（不删除）输入文件
-f, --force         强制覆盖输出文件和（取消）压缩链接
-c, --stdout        写入标准输出，不删除输入文件
-0 .. -9            压缩预设；0-2快速压缩，3-5良好
                    压缩，6-9极好的压缩；默认值为6
```

**将 ramdisk.img 解压出来修改 init，再重新打包压缩回 ramdisk.img**

```sh
# 解压
mv ramdisk.img ramdisk.img.xz
unxz ramdisk.img.xz
cpio -i -F ramdisk.img   #解压cpio

write /dev/kmsg "INIT: early-init entry"

# 打包
find . |cpio -ov -H newc | xz -9  --check=crc32  > ../ramdisk.img
```

> 最后 uboot中执行 dmesg 查看日志 -- 带时间戳

## arecord、aplay、amixer 使用

> 上传音频数据 adb push .\the-stars-48k-60s.wav /data/

### arecord与aplay

```sh
arecord  -l  # 查询 linux 系统下设备声卡信息

arecord -D hw:0,0 -r 16000 -c 1 -f S16_LE test.wav  # 录制音频

Recording WAVE 'test.wav' : Signed 16 bit Little Endian, Rate 16000 Hz, Mono
^CAborted by signal Interrupt...  # 这里使用Ctrl+c 结束了录制

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav   # 播放音频
```


### amixer

- amixer controls 用于查看音频系统提供的操作接口
- amixer contents 用于查看接口配置参数
- amixer cget + 接口函数
- amixer cset + 接口函数 + 设置值

```sh
dmesg  -n 8   # 开 log
amixer cget numid=2       # 查看音量
amixer cset numid=2 150   # 修改音量
# 或者
amixer cset numid=2,iface=MIXER,name='tas5805 Digital Volume' 150

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav 
```

#### 在 Ubuntu 下测试

进入 codecs

adb shell



## 打印 iomem 寄存器地址

```c
void __iomem *reg

printk(" reg: 0x%x \n", readl(ioremap(reg, 1))); 
```




## 芯片代称对应

spencer是C2

gq/nq是C1

korlan 是A1

newman是G12B

elaine是SM1



-----

# Korlan

## korlan Sync

参考：[Sync chrome and korlan](https://confluence.amlogic.com/display/SW/Sync+chrome+and+korlan)

```sh
cd eureka && mkdir amlogic_sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b korlan-master -m combined_sdk.xml
repo sync
```

> Baud rate 为 115200

## 编译korlan

```sh
cd bl2
./build_bl2.sh korlan-b1 ../u-boot release
cd -
#输出 cp ./aml_ddr.fw ../u-boot/fip/a1/

cd bl31
./build_bl31.sh korlan-b1 ../u-boot release
cd -
# 输出：cp -v build/c2/release/bl31.img ../u-boot/fip/a1/

# 修改pthon脚本 scripts/pack_kpub.py  #+#!/usr/bin/env python
cd bl32
./build_bl32.sh korlan-b1 ../u-boot release 
cd -
# 输出： cp -v out/bl32.img ../u-boot/fip/a1/

cd u-boot
./build_uboot.sh korlan-b1 ../../chrome release
cd -
# 编译： # ./mk a1_korlan_b1 --board_name korlan-b1 --bl2 fip/a1/bl2.bin --bl30 fip/a1/bl30.bin --bl31 fip/a1/bl31.img --bl32 fip/a1/bl32.img release
# 输出： /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/korlan/prebuilt/bootloader

cd kernel
./build_kernel.sh korlan-b1  ../../chrome
cd -

```

- 整体编译

```sh
cd amlogic_sdk
./sdk/build_scripts/build_all.sh ../chrome korlan-p2
```


## 制作 ramdisk


【下载地址】: https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/korlan-eng;tab=objects?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false

将下载解压出来的 boot.img 拷贝到 unpack_boot_ramdisk_script 目录下

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/unpack_boot_ramdisk_script
bash unpack_boot.sh ./boot.img ./boot_out unpack_boot 

# 解压出ramdisk.img.xz 之后，拷贝
cp ramdisk.img.xz /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk/korlan/ramdisk.img
```

## 签名korlan

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk
mkdir -p ./korlan/korlan-b1

# 签名 uboot
./sign-uboot.sh ../../chrome ./korlan/korlan-b1 b1

# 签名kernel
# ramdisk 需要拷贝到 ./korlan/ramdisk.img
./sign-kernel.sh ../../amlogic_sdk korlan/korlan-b1 b1 ../../chrome
```

## 烧录korlan

```sh
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
adnl.exe Partition -P boot  -F boot-sign.img
adnl.exe Partition -P system  -F system.img
adnl.exe oem "reset"
```



## 编译korlan-ota

```sh
cd chrome
source build/envsetup.sh 

# 全部编译 korlan-eng
lunch  # 选korlan-eng
PARTNER_BUILD=true BOARD_NAME=korlan-p2 make -j30 otapackage  
# 输出obj路径： /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/korlan

# 如果出现 java version 问题，就是 out/host/linux-x86 的 dumpkey.jar  signapk.jar 替换过了，需要替换回repo sync 时候的 linux-x86 就可以了
```


---



# Spencer

## spencer烧录

```sh
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
adnl.exe Partition -P boot_a  -F boot.img
adnl.exe Partition -P boot_b  -F boot.img
adnl.exe Partition -P misc  -F misc.img
adnl.exe Partition -P system_b  -F fct_boot.img
adnl.exe oem "enable_factory_boot"   # adnl.exe oem "disable_factory_boot" 
adnl.exe oem "reset"
```


## 

----



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





----



# ramdisk.img 解包

```sh
# 解压 korlan的ramdisk
file ramdisk.img
mv ramdisk.img ramdisk.img.xz
unxz ramdisk.img.xz
cpio -i -F ramdisk.img   #解压cpio

# 打包
find . |cpio -ov -H newc | xz -9  --check=crc32  > ../ramdisk.img
```

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





## 







