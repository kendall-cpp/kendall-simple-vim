
- [NN模型测试和转换](#nn模型测试和转换)
  - [编译出 ssd\_small\_multiout\_be.nb](#编译出-ssd_small_multiout_benb)
- [TASK: VSI 版本编译问题 bug](#task-vsi-版本编译问题-bug)
  - [复现测试](#复现测试)
    - [update kernel \& uboot \& system](#update-kernel--uboot--system)
    - [编译 spencer ota 包](#编译-spencer-ota-包)
    - [Replace bootloader](#replace-bootloader)
      - [拷贝解压烧录](#拷贝解压烧录)
      - [解决 adb 无法 push 问题](#解决-adb-无法-push-问题)
      - [push 静态库](#push-静态库)
    - [无法通过 reboot update 进入烧录模式](#无法通过-reboot-update-进入烧录模式)
      - [测试问题main.cpp](#测试问题maincpp)
- [Task: 更新 verisilicon 驱动](#task-更新-verisilicon-驱动)
  - [切换至 NQ 项目](#切换至-nq-项目)
    - [下载 ota 烧录包](#下载-ota-烧录包)
      - [拉取最新代码](#拉取最新代码)
    - [编译 gqnq-sdk](#编译-gqnq-sdk)
      - [Bootloader (bl2 + bl31 + bl32 + u-boot)](#bootloader-bl2--bl31--bl32--u-boot)
      - [arm RTOS](#arm-rtos)
      - [Kernel](#kernel)
      - [isp module](#isp-module)
      - [NN module](#nn-module)
    - [签名](#签名)
    - [烧录](#烧录)
    - [充电](#充电)
    - [自己制作ota包](#自己制作ota包)
  - [Task: FPN 模型](#task-fpn-模型)
  - [freertos](#freertos)
    - [freertos 编译脚本分析](#freertos-编译脚本分析)
- [AV400 NN模型测试](#av400-nn模型测试)
  - [测试环境](#测试环境)
  - [buildroot整理](#buildroot整理)
  - [开始测试](#开始测试)
    - [修改代码-使得 vsi 能够在 av400 中测试](#修改代码-使得-vsi-能够在-av400-中测试)
    - [insmod galcore时 error](#insmod-galcore时-error)
      - [fix](#fix)
    - [编译 case 模型时出错](#编译-case-模型时出错)
    - [重新编译 FPN\_be 修改 optimize](#重新编译-fpn_be-修改-optimize)
    - [测试 case 错误](#测试-case-错误)
      - [解决](#解决)
  - [升级到 NN6.4.11.2](#升级到-nn64112)
    - [下载 6.4.11.2 压缩包并一个个解压](#下载-64112-压缩包并一个个解压)
      - [build](#build)
    - [在 av400 上测试](#在-av400-上测试)
    - [下载 actuity tool](#下载-actuity-tool)
      - [到 linux 上重新编译 NN case](#到-linux-上重新编译-nn-case)
    - [测试模型](#测试模型)
      - [ssd\_small\_multiout\_be](#ssd_small_multiout_be)
      - [FPN](#fpn)
      - [alexnet\_caffe](#alexnet_caffe)
      - [googlenet\_caffe](#googlenet_caffe)
      - [mobilenetv1](#mobilenetv1)
      - [yolov2](#yolov2)
      - [inceptionv1](#inceptionv1)
      - [ssd\_mobilenet\_v1](#ssd_mobilenet_v1)
      - [ssd\_big\_multiout](#ssd_big_multiout)
  - [verisilicon 6.4.11.2](#verisilicon-64112)


---



# NN模型测试和转换

> 总结文档 https://drive.google.com/drive/my-drive?hl=zh-CN

## 编译出 ssd_small_multiout_be.nb

ubuntu 记录

- 转换模型

需要转换的模型： Z:\workspace\google_source\eureka\spencer-sdk\NN649\AML_OUTPUT\All_precompile_bin\All_pre-compiled_bin\spencer\model

```sh
# ~/NN/649/actool_6.3.1/acuity-toolkit-binary-6.3.1/google_test_mode
vim alexnet_caffe/alexnet_caffe_03.sh 
vim alexnet_caffe/alexnet_caffe_02.sh 
vim alexnet_caffe/alexnet_caffe_01.sh 

# 查看输出
# vim yolov2/export_nbg_be.sh 

cd ssd_small_multiout
# ~/NN/649/actool_6.3.1/acuity-toolkit-binary-6.3.1/google_test_model/ssd_small_multiout

# 编译 ssd_small_multiout
$ bash step1.sh ssd_small_multiout
$ bash step2.sh ssd_small_multiout
# rm iter_0_*
# rm ssd_small_multiout_be/ -rf

# rm ssd_small_multiout.data 
# rm ssd_small_multiout.quantize 
# rm ssd_small_multiout.quantize 
# rm tflite.export.data 
# rm ssd_small_multiout.json 

bash step1.sh ssd_small_multiout
vim ssd_small_multiout.json
vim ssd_small_multiout_inputmeta.yml

bash step2.sh ssd_small_multiout
vim ../ssd_big_multiout/ssd_big_multiout_04_be.sh

bash step3.sh ssd_small_multiout
ls ssd_small_multiout_be/ -al

bash step4_inference.sh ssd_small_multiout
```

- 编译模型

> 模型测试需要退 verisilicon 回到 a3a7bfc470082aad8dd4fade29fabddb7deb850b 这个 commit



```sh
# cp  /mnt/fileroot/yuegui.he/c2/amlogic_sdk/alexnet_caffe_be/build_vx.sh .
# 注意修改成自己的路径

./build_vx.sh 

# 修改  makefile.linux 
vim makefile.linux 
# 114 TARGET_NAME = tflite 

./build_vx.sh 
```

- 测试模型

```sh
Z:\workspace\google_source\eureka\spencer-sdk\verisilicon\build\sdk> adb.exe push .\drivers\. /lib/

# \workspace\google_source\eureka\spencer-sdk\alexnet_caffe_be\bin_r>
rmmod iv009_isp
rmmod iv009_isp_sensor
rmmod iv009_isp_lens
rmmod iv009_isp_iq 
rmmod galcore 
rmmod dhd

insmod galcore.ko showArgs=1

./tflite ./alexnet_caffe_be.nb iter_0_input_0_out0_1_3
./tflite ./alexnet_caffe_be.nb ./space_shuttle.jpg 
```

- **转换输出文件为 txt**

修改 vnn_post_process.c 46 行

```c
vsi_nn_SaveTensorToTextByFp32(graph, tensor, filename, "\n");
或者
vsi_nn_SaveTensorToTextByFp32( graph, tensor, filename, NULL );
```

-----

# TASK: VSI 版本编译问题 bug

> https://partnerissuetracker.corp.google.com/issues/242716462

在 chrome 中编译 spencer-p2 命令： ./build_ml.sh arm64 spencer-p2 ../../chrome/

编译一个 spencer ota 包

```sh
cd chrome/

source build/envsetup.sh 

# PARTNER_BUILD=true lunch spencer-eng
PARTNER_BUILD=true lunch

make BOARD_NAME=spencer-p2 PARTNER_BUILD=true  -j12 otapackage
```

## 复现测试

> https://partnerissuetracker.corp.google.com/issues/242716462

```sh
# pull 之后 编译并执行
cd verisilicon && ./build_ml.sh arm64 spencer-p2 ../../chrome/
eureka/spencer-sdk/NN649/issue$
../../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang++ main.cpp -o main.o -L ../../verisilicon/build/sdk/drivers -static -Wl,--whole-archive -lovxlib
```


### update kernel & uboot & system
### 编译 spencer ota 包

**参考**： https://confluence.amlogic.com/display/SW/6.+Spencer+OTA+Repacked

### Replace bootloader

下载 otatools 和 spencer-target_files 两个 zip 文件

[下载地址](https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master/spencer-eng/315654?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)

- otatools

```sh
mkdir spencer-315654

cd spencer-315654

spencer-315654/spencer-otatools$ unzip  otatools.zip 

# 获取mkbootimg  和 mkbootfs 
```

- missing-binary

下载 [missing-binary.zip](https://confluence.amlogic.com/download/attachments/180725736/missing-binary.zip?version=2&modificationDate=1651397450635&api=v2)

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/spencer-315654
mkdir missing-binary && mv missing-binary.zip missing-binar
unzip -o missing-binary.zip

# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
cp spencer-315654/missing-binary/make_ext4fs  build/bin/
cp spencer-315654/missing-binary/mkbootfs  build/bin/
cp spencer-315654/missing-binary/veritysetup  build/bin/

cp spencer-315654/missing-binary/signapk.jar ./build/framework/
cp spencer-315654/missing-binary/dumpkey.jar ./build/framework/

cp spencer-315654/missing-binary/dumpkey.jar ./out/host/linux-x86/framework/
cp spencer-315654/missing-binary/signapk.jar ./out/host/linux-x86/framework/

chmod 755 ./build/bin/make_ext4fs ./build/bin/mkbootfs ./build/bin/veritysetup 
```

- spencer-target_files

```sh
mkdir spencer-target_files && cd spencer-target_files
unzip spencer-target_files.zip

# 设置环境变量
export PATH="$PATH:/mnt/nfsroot/zhiqi.lai/eureka/chrome/build/bin/"
```

- 编译 u-boot 和 kernel

```sh
cd spencer-sdk

# 编译bootloader
cd bl2 && ./build_bl2.sh spencer-p2
cd bl31 && ./build_bl31.sh spencer-p2 
cd bl31 && ./build_bl31.sh spencer-p2 
cd u-boot && ./build_uboot.sh spencer-p2 ../chrome/
# 编译出来的文件在： ll -t vendor/amlogic/spencer/prebuilt/bootloader/

# 编译kernel 和 modules
cd kernel && ./build_kernel.sh spencer-p2 ../../chrome/
# 编译出来的文件在：ll -t vendor/amlogic/spencer/prebuilt/kernel/
cd verisilicon && ./build_ml.sh arm64 spencer-p2 ../../chrome/  # 可以不编译
# 编译出来的文件在： ll -t vendor/amlogic/spencer/prebuilt/kernel/modules/
```

- 拷贝和打包zip

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/spencer-315654/spencer-target_file
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/aml_ddr.fw BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl2_new.bin.spencer-p2 BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl31.img.spencer-p2  BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl32.img.spencer-p2  BOOT/bootloader/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/bootloader/bl33.bin.spencer-p2  BOOT/bootloader/

zip -r ./spencer-target_files.zip -f ./BOOT/bootloader


cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/kernel/modules/*spencer-p2.ko ./BOOT/RAMDISK/lib/kernel/modules/
cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/spencer/prebuilt/kernel/kernel.spencer.gz-dtb.spencer-p2 ./BOOT/RAMDISK/lib/kernel/kernel-spencer-p2 

zip -r ./spencer-target_files.zip -f ./BOOT/RAMDISK/lib/


cd ../../

mv out/host/linux-x86/bin out/host/linux-x86/bin1

./vendor/amlogic/build/tools/releasetools/ota_from_target_files -v --board spencer-p2 ./spencer-315654/spencer-target_files/spencer-target_files.zip ./spencer-315654/replace-bootloader-kernel-ota.zip
```

#### 拷贝解压烧录

解压

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/replace-ota/spencer-315654
unzip replace-bootloader-kernel-ota.zip 
cat bl2.bin tpl.bin > u-boot.bin
```

烧录

```sh
#  download boot & system
adnl.exe  Partition -M mem -P 0x2000000 -F u-boot.bin
adnl.exe oem "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a  -F tpl.bin
adnl.exe Partition -P tpl_b  -F tpl.bin
adnl.exe Partition -P boot_a  -F boot.img
adnl.exe Partition -P boot_b  -F boot.img
adnl.exe Partition -P system_a  -F system.img
adnl.exe oem "reset"
```

启动完成后解决无法 adb push 问题


#### 解决 adb 无法 push 问题

修改kernel代码

```c
// vim kernel/arch/arm64/boot/dts/amlogic/spencer-p2.dts 

1266     /*controller-type = <3>;*/
1267     controller-type = <2>;   
```

重新编译打包和烧录

执行脚本

```
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
echo ff500000.dwc2_a > /sys/kernel/config/usb_gadget/amlogic/UDC
```


#### push 静态库

```sh
adb.exe push .\drivers\. /data/

# 还需要在这里把 Z:\windowFile\Spencer_SDK文件\NN649\issue\drive-download-20220905T020706Z-001 把 benchmark_model 和 libneural_network_models.so push 到 /data

# push 

Z:\workspace\google_source\eureka\spencer-sdk\verisilicon\build\sdk> adb.exe push .\drivers\. /data/

Z:\workspace\google_source\eureka\spencer-sdk\NN649\issue\age_asymu8> adb.exe push .\bin_r\mynn .\mynn.export.data .\iter_0_input_0_out0_1_3_227_227.tensor /data

Z:\windowFile\Spencer_SDK文件\NN649\issue\drive-download-20220905T020706Z-001> adb.exe push benchmark_model /data
benchmark_model: 1 file pushed. 1.2 MB/s (41976 bytes in 0.034s)
Z:\windowFile\Spencer_SDK文件\NN649\issue\drive-download-20220905T020706Z-001> adb.exe push libneural_network_models.so /data


# 到板子上设置环境变量
export LD_LIBRARY_PATH=/data:$LD_LIBRARY_PATH

rmmod dhd
rmmod galcore
rmmod iv009_isp
rmmod iv009_isp_sensor
rmmod iv009_isp_lens
rmmod iv009_isp_iq
rmmod overlay
rmmod exportfs

insmod /data/galcore.ko

chmod 777 /data/*



# 声明环境变量 打印更多信息
export VIV_VX_DEBUG_LEVEL=1
export VIV_NN_LOGLEVEL=5

# 开始测试
cd /data && ./mynn ./mynn.export.data ./iter_0_input_0_out0_1_3_227_227.tensor 


# 测试module
VIV_VX_DEBUG_LEVEL=1 benchmark_model -m VsiCustomFpn
VIV_VX_DEBUG_LEVEL=1 benchmark_model
```




### 无法通过 reboot update 进入烧录模式

> 研究

更改模式

```sh
cat /proc/fts 
fts -s bootloader.command  # 设置bootloader命令
fts -i  #清除工厂模式

start usb_update; reboot update;
```

关闭或者打开 factory boot    

```
vim cmd/amlogic/cmd_factory_boot.c     
vim cmd/amlogic/cmd_reboot.c  
```

#### 测试问题main.cpp

```sh
spencer-sdk/NN649/issue$ ../../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang++ main.cpp -o main.o -L ../../verisilicon/build/sdk/drivers -static -W1,--whole-archive -lovxlib
```


----


# Task: 更新 verisilicon 驱动

- 解压并添加所有的 tgz 包，并 git commit

```sh
tar -zxf Vivante_GALVIP_Unified_Src_drv_6.4.9.tgz -C Vivante_GALVIP_Unified_Src_drv

# 进入解压的目录并拷贝
cp * ../../../../test-verisilicon/ -r

# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/test-verisilicon
```

- git commit 

```sh
Import from Vivante_GALVIP_Unified_Src_tst_OVX-addon_6.4.9.tgz

Bug: None
Test: None

```

- 找到这个提交开始，往后所有的 commit 都需要 cherry-pick 一遍

```
commit d678e2143cdfad171c3ef5c27c3900c053b135cb
Author: yuegui.he <yuegui.he@amlogic.corp-partner.google.com>
Date:   Thu Sep 16 14:45:06 2021 +0800

    Copy over .gitignore from AML's initial drop
    
    Bug: b/204773314
    Test: None
    Change-Id: Iac0703a6423d1287c928bb684140178f507f137a
    Signed-off-by: yuegui.he <yuegui.he@amlogic.corp-partner.google.com>
    (cherry picked from commit 5461fb121c68e387b279dd97924dfb932aaa56ea)
```


git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/96/233896/2 && git cherry-pick FETCH_HEAD -x

git add 

git commit -s

-x 表示记录从哪里 cherry-pick 来的

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/97/233897/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/98/233898/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/99/233899/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/01/233901/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/02/233902/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/03/233903/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/25/243025/1 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/26/243026/1 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/45/245445/2 && git cherry-pick FETCH_HEAD -x

git fetch https://eureka-partner.googlesource.com/verisilicon-sdk refs/changes/27/245927/1 && git cherry-pick FETCH_HEAD -x

- 编译打包烧录，测试 model

----

## 切换至 NQ 项目

----

repo init -u  https://eureka-partner.googlesource.com/amlogic/manifest -b quartz-master  -m combined_sdk.xml

repo init -u https://eureka-partner.googlesource.com/amlogic/freertos -b quartz-master  -m combined_sdk.xml

repo sync

----

拷贝 spencer-sdk 至 GQNQ-sdk 

```sh
cp spencer-sdk GQNQ-sdk -rfL  # -rfL 表示拷贝git信息
```

切换分支 ： `bl31 bl32 uboot kernel` 都是 quartz-master

bl2 是 quartz-master-v2


### 下载 ota 烧录包

Catbuild 在线下载网址：https://console.cloud.google.com/storage/browser/cast-partner-amlogic-internal/internal/master;tab=objects?authuser=1&prefix=&forceOnObjectsSortingFiltering=false

这里以NQ为例，为了方便开发，我们选择开发版本 gq-eng, 版本号选择  

`cast-partner-amlogic-internal/internal/master/gq-eng/316798`

#### 拉取最新代码

git pull eureka-partner HEAD:refs/for/quartz-master-v2

报错

```sh
Removing tools/acs_tool/acs_tool.pyc
Auto-merging tools/acs_tool/acs_tool.py
CONFLICT (content): Merge conflict in tools/acs_tool/acs_tool.py
Auto-merging Makefile.gcc
Recorded preimage for 'tools/acs_tool/acs_tool.py'
Automatic merge failed; fix conflicts and then commit the result.
```

解决

```sh
git reset HEAD .  # 从暂存区删除到工作区

 git clean -f

git reset --hard FETCH_HEAD

git pull eureka-partner quartz-master-v2 / quartz-master
```

### 编译 gqnq-sdk

#### Bootloader (bl2 + bl31 + bl32 + u-boot)

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
#!/usr/bin/env python2    第一行


cd u-boot
./build_uboot.sh gq-b3 ./../../chrome release
cd -
```

####  arm RTOS

```sh
cd freertos
./build_rtos.sh gq-b3 ./../../chrome release --skip-dsp-build
cd -
```

#### Kernel

```sh
cd kernel
./build_kernel.sh gq-b3 ./../../chrome 
cd -
```

#### isp module

```
cd lloyd-isp
./build_isp.sh gq-b3 ./../../chrome 
cd -
```

#### NN module

```sh
cd verisilicon
./build_ml.sh arm64 gq-b3 ./../../chrome 
cd -
```

### 签名

```sh
# 签名uboot
cd pdk
./create-uboot.sh -b  gq-b3

# 签名kernel
unpack_boot.sh ./boot.img ./boot_out unpack_boot 
# 制作好ramdisk
# mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/target/product/gq
mkdir boot_unpack
# 拷贝ramdisk.img进去

# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/pdk
./build-bootimg.sh -b  gq-b3
```

### 烧录

- 强制烧录:（按住复位键 - 直到串口打印处rom code) ，按照step 0~6 进行

```sh
:: step 0

u-boot.bin 是由 bl2.bin tpl.bin 拼起来，可以用cat 命令生成 : cat bl2.bin tpl.bin > u-boot.bin
adnl.exe Download bl2.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F u-boot.bin
# --> sleep 3
```

- 正常烧录：按照 step 1~6 进行

```sh
fts -c

fts -i   # 关闭工程模式

start usb_update; reboot update;   # 重启进入烧录模式
```

```sh
:: step 1
adnl.exe oem store init 1
adnl.exe oem mmc dev 1

:: step 2
adnl.exe partition -M mem -P 0x2000000 -F bl2.bin
adnl.exe cmd "store boot_write bootloader 0x2000000 0x1ffe00"
adnl.exe Partition -P tpl_a -F tpl.bin
adnl.exe Partition -P tpl_b -F tpl.bin

:: step 3
adnl.exe Partition -P misc -F misc.img

:: step 4
adnl.exe Partition -P boot_a -F boot.img
adnl.exe Partition -P boot_b -F boot.img

:: step 5
adnl.exe partition -P rtos_a -F rtos.img
adnl.exe partition -P rtos_b -F rtos.img

:: step 6
adnl.exe Partition -P system_a -F system.img
```

- 通过 pdk 签名的烧录命令

```sh
# start usb_update; reboot update;
adnl.exe Download bl2.signed.bin 0x10000
adnl.exe run
adnl.exe bl2_boot -F u-boot.signed.bin

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


### 充电


```sh
# 使用 nlspi_client 命令
# 参数 -fault_mode=<1 or 0>           Set/Clear battery fault mode
nlspi_client -fault_mode=0  #清除电池错误状态
logcat -s iot_power  # 查看充电状态
```


### 自己制作ota包

下载 gq_target_file.zip

拷贝到 ${your_sdk}/GQ-ota

```sh
unzip gq-target_files.zip 

# 配置环境变量
export PATH=/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/build/bin/:$PATH


GQNQ-sdk$ cd bl2; ./build_bl2.sh gq-b3 ; cd -;
GQNQ-sdk$ cd bl31; ./build_bl31.sh gq-b3 ; cd -;
GQNQ-sdk$ cd bl32; ./build_bl32.sh gq-b3 ; cd -;
GQNQ-sdk$ cd u-boot; ./build_uboot.sh gq-b3 ../../chrome/ ; cd -;

GQNQ-sdk$ cd kernel; ./build_kernel.sh gq-b3 ~/eureka/chrome/; cd -;
GQNQ-sdk$ cd ../chrome

# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/GQNQ-sdk/GQ-ota/gq_target_file
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/aml_ddr.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/bl2_new.bin.gq-b3 ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/bl30_new.bin.gq-b3 ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/bl31.img.gq-b3 BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/bl32.img.gq-b3 BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/bl33.bin.gq-b3 BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/ddr4_1d.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/ddr4_2d.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/ddr3_1d.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/piei.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/lpddr4_1d.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/lpddr4_2d.fw ./BOOT/bootloader
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/bootloader/diag_lpddr4.fw ./BOOT/bootloader

zip -r ./gq-target_files.zip -f ./BOOT

# kernel & moduel

# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/GQNQ-sdk/GQ-ota/gq_target_file
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/root_modules/galcore.gq-b3.ko ./BOOT/RAMDISK/lib/modules/galcore.gq-b3.ko 
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/kernel/modules/*gq-b3.ko ./BOOT/RAMDISK/lib/kernel/modules/
 cp /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/kernel/kernel.gq.gz-dtb.gq-b3 ./BOOT/RAMDISK/lib/kernel/kernel-gq-b3 

 zip -r ./gq-target_files.zip -f ./BOOT

cd /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
mv out/host/linux-x86/bin out/host/linux-x86/bin1
./vendor/amlogic/gq/build/tools/releasetools/ota_from_target_files -v --board gq-b3 ../GQNQ-sdk/GQ-ota/gq_target_file/gq-target_files.zip /mnt/fileroot/shengken.lin/workspace/google_source/eureka/replace-ota/gq-replace-ota/replace-gq-ota.zip
# error: FileNotFoundError: [Errno 2] No such file or directory: 'pack_arbt_2.4.0.py'
# 需要拷贝otatool到相应目录，参考spencer
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/GQNQ-sdk/GQ-ota/otatools
cp ./framework/signapk.jar ../../../chrome/build/framework
cp ./framework/dumpkey.jar ../../../chrome/build/framework
cp ./framework/dumpkey.jar ../../../chrome/out/host/linux-x86/framework
cp ./framework/signapk.jar ../../../chrome/out//host/linux-x86/framework
# make_ext4fs 要用和spencer一样的


mv out/host/linux-x86/bin1 out/host/linux-x86/bin
```


## Task: FPN 模型

> 测试模型需要回退到 commit id: a3a7bfc470082aad8dd4fade29fabddb7deb850b

```sh
rmmod iv009_isp 
rmmod iv009_isp_sensor 
rmmod iv009_isp_lens 
rmmod iv009_isp_iq 
rmmod galcore  
rmmod dhd  


 Z:\workspace\google_source\eureka\spencer-sdk\verisilicon\build\sdk\drivers> adb.exe push .\. /lib


insmod /lib/galcore.ko 

 mkdir /cache/FPN_be

 
Z:\workspace\google_source\eureka\spencer-sdk\FPN_be> adb.exe push .\bin_r\tflite .\FPN_be.nb /cache/FPN_be
Z:\workspace\google_source\eureka\NN-spencer-file\NN649\AML_OUTPUT\All_precompile_bin\All_pre-compiled_bin\spencer\model\FPN_be> adb.exe push .\640.jpg  .\iter_0_input_0_out0_1_640_640_3.tensor /cache/FPN_be

 chmod 777 *

./tflite FPN_be.nb 640.jpg 
# Create Neural Network: 81ms or 81277us
# Verify...
# Verify Graph: 15ms or 15634us
# Start run graph [1] times...
# Run the 1 time: 146.40ms or 146396.08us
# vxProcessGraph execution time:
# Total   146.49ms or 146490.78us
# Average 146.49ms or 146490.78us
#  --- Top5 ---
# 153323: 4.838949
# 153347: 4.782682
# 152027: 4.613881
# 152051: 4.613881
# 153371: 4.613881
./tflite FPN_be.nb iter_0_input_0_out0_1_640_640_3.tensor 
# Create Neural Network: 222ms or 222784us
# Verify...
# Verify Graph: 3ms or 3037us
# Start run graph [1] times...
# Run the 1 time: 146.51ms or 146511.25us
# vxProcessGraph execution time:
# Total   146.60ms or 146602.12us
# Average 146.60ms or 146602.12us
#  --- Top5 ---
# 153323: 5.007749
# 153347: 5.007749
# 153371: 5.007749
# 153299: 4.782682
# 153395: 4.670148

```

- cherry pick

```sh
cd freertos
git fetch https://eureka-partner.googlesource.com/amlogic/freertos refs/changes/41/208141/2 && git cherry-pick FETCH_HEAD
git fetch https://eureka-partner.googlesource.com/amlogic/freertos refs/changes/42/208142/3 && git cherry-pick FETCH_HEAD
git fetch https://eureka-partner.googlesource.com/amlogic/freertos refs/changes/03/208503/4 && git cherry-pick FETCH_HEAD
```

- 编译 rtos

```sh
cd freertos
./build_rtos.sh gq-b3 ./../../chrome release --skip-dsp-build
```

- 签名 rtos

```sh
# 编译出来的镜像文件在 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/rtos/rtos-uImage.gq-b3
cd pdk
./sign_rtos.sh -i /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/gq/prebuilt/rtos/rtos-uImage.gq-b3 -b  gq-b3
```

- 编译 gq kernel 签名 kernel


- 烧录 rtos

```sh
start usb_update; reboot update;


adnl.exe partition -P rtos_a -F rtos.img
adnl.exe partition -P rtos_b -F rtos.img

adnl.exe oem "reset"
```

- 或者编译全部

```sh
 bash ./sdk/build_scripts/build_all.sh ../chrome/  gq
```

-----

## freertos 

```sh
# 修改代码
# /freertos/demos/amlogic/xtensa_hifi4/c2_venus_flatbuftest_hifi4a/boot/startdsp.c

# ./build_ml.sh arm64 gq-b3 ./../../chrome 
bash build_hifi_tests.sh debug 
# 输出：freertos\hifi_tests\c2_venus_flatbuftest_hifi4a.bin
# Z:\workspace\google_source\eureka\spencer-sdk\freertos\hifi_tests> 
adb push .\c2_spencer_flatbuftest_hifi4a.bin /data/

cp /data/c2_spencer_flatbuftest_hifi4a.bin /system/lib/firmware/dspboot.bin 

cp /data/c2_spencer_flatbuftest_hifi4a.bin /lib/firmware/dspboot.bin 

sync

dsp_util --dsp=hifi4a -s
dsp_util --dsp=hifi4a -r
dsp_util --dsp=hifi4a --firmware=dspboot.bin -l
dsp_util --dsp=hifi4a -S

# 查看结果： cat /sys/kernel/debug/hifi4frtos/hifi4
```

### freertos 编译脚本分析

```sh
./build_rtos.sh spencer-p2 ./../../chrome release --skip-dsp-build

build_hifirtos()
  scripts/amlogic/mk.sh  c2_spencer_hifi4a

cp ./out_dsp/dspboot.bin.gz chrome/vendor/amlogic/spencer/prebuilt/bootloader/dspa.bin.spencer-p2
```



# AV400 NN模型测试

> https://jira.amlogic.com/browse/GH-3183

```sh
cd /mnt/fileroot/shengken.lin/workspace/a1_buildroot/bootloader/uboot-repo/bl33/v2019
git pull amlogic amlogic-dev-2019

cd /mnt/fileroot/shengken.lin/workspace/buildRoot_A1/kernel/aml-5.4

分支：amlogic/amlogic-5.4-dev

git pull amlogic HEAD:refs/for/amlogic-5.4-dev

source setenv.sh 
11. a5_av400_a6432_release

/mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon$ git pull eureka-partner quartz-master
```


## 测试环境

- SW: buildroot a113x2   -- 对应 a5_buildroot av400 的代码
- HW: AV400             -- 硬件
- NPU driver: google 6.4.9 driver.    -- google 的 vsi 驱动
- dts: ./arm64/boot/dts/amlogic/a5_a113x2_av400_1g.dts

- output下kernel的路径

output/a5_av400_a6432_release/build/linux-amlogic-5.4-dev


- 修改 /build_ml.sh
- 编译 ./build_ml.sh arm-amlogic spencer-p2 ./../../chrome

- 编译 AV400

```sh
source setenv.sh   # 11. a5_av400_a6432_release
make show-targets | grep npu
make npu-rebuild
make linux-rebuild
```

## buildroot整理

 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/configs/amlogic/npu_driver_k5.4.config 

 这里会配置一下全局的局部变量，给 package/amlogic 下的各个 package 用

 比如给 `vim package/amlogic/npu/npu.mk`  使用

```sh
 cd $(@D);./aml_buildroot.sh $(KERNEL_ARCH) $(LINUX_DIR) $(TARGET_KERNEL_CROSS)
#  cd /mnt/fileroot/shengken.lin/workspace/a5_buildroot/output/a5_av400_a6432_release/build/npu-1.0;./aml_buildroot.sh arm64 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/output/a5_av400_a6432_release/build/linux-amlogic-5.4-dev /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/../toolchain/gcc/linux-x86/aarch64/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
```


- test commit: 057b4ec654b6384de7089fdc80dd6f6fff5dc20e


- 预编译的包目录

```
verisilicon/driver/khronos/libOpenVX/vipArchPerfMdl_dev

verisilicon/compiler
```

- 编译出来的 so 目录

```sh
verisilicon/build/sdk/drivers 
```


## 开始测试

push 动态库和 ko 文件

编译成功后，将 galcore.ko 文件 push 到 av400 的 /data 下

```sh
Z:\workspace\google_source\eureka\spencer-sdk\verisilicon> adb.exe push .\galcore.ko /data
Z:\workspace\google_source\eureka\spencer-sdk\verisilicon> adb.exe push .\build\sdk\drivers\ /usr/lib/

insmod /data/galcore.ko
```

----

###  修改代码-使得 vsi 能够在 av400 中测试

```sh
vim hardware/aml-5.4/npu/nanoq/hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c 
vim spencer-sdk/verisilicon/hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c 
```

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


### insmod galcore时 error

```sh
# insmod /data/galcore.ko

# error
[   85.209473@0]  Unable to handle kernel read from unreadable memory at virtual address ffffff82bd534b30
[  113.222304@2]  Unable to handle kernel read from unreadable memory at virtual address ffffff8a7d534b30
```


#### fix

```c
npu_core_clk = devm_clk_get(&pdev->dev, "cts_vipnanoq_core_clk_composite");
//clk_put(npu_core_clk);
```


### 编译 case 模型时出错

```sh
build/sdk/drivers/libCLC.so, not found (try using -rpath or -rpath-link)
sdk/drivers/libArchModelSw.so, not found (try using -rpath or -rpath-link)
```

- 解决

```sh
# 修改编译脚本
export FIXED_ARCH_TYPE=aarch64-gnu
```

- build/sdk/driver 下的 so 是复制的

```sh
# verisilicon/compiler/libVSC/makefile.linux  
cp -f arm64/libVSC.so /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon/build/sdk/drivers 
```

### 重新编译 FPN_be 修改 optimize

```sh
$pegasus_bin export ovxlib \
	--model ${NAME}.json \
	--model-data ${NAME}.data \
	--model-quantize ${NAME}.quantize \
	--with-input-meta ${NAME}_inputmeta.yml \
	--dtype quantized \
    --optimize VIPNANOQI_PID0XA1 \     #### VIP9000NANOS_PID0X1000000E
    --viv-sdk /home/amlogic/VeriSilicon/VivanteIDE5.6.0/cmdtools/ \
    --output-path ${NAME}/ \
    --pack-nbg-unify
```

### 测试 case 错误

```sh
/data/FPN # ./tflite
/bin/sh: ./tflite: not found
```

#### 解决

**需要编译 32 位的应用去测试**

修改编译脚本

```sh
- export FIXED_ARCH_TYPE=aarch64-gnu
+ export FIXED_ARCH_TYPE=arm-linux-gnueabihf
```

- **编译 ddk**

```sh
./build_ml.sh arm32 spencer-p2 ./../../chrome
```


在这里去找 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/configs/amlogic/arch_a6432_10.3_7.3.1.config  应用所用的编译器

```sh
# FPN_be\build_vx.sh
    ################### arm 32
    TOOLCHAIN_DIR=/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/arm/gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf
    CROSS=${TOOLCHAIN_DIR}/bin/arm-none-linux-gnueabihf-

    ARCH=arm
    export ARCH_TYPE=$ARCH
    export CPU_TYPE=cortex-a9
    export CPU_ARCH=armv7-a
    export FIXED_ARCH_TYPE=arm-gnueabihf
    # export FIXED_ARCH_TYPE=arm-linux-gnueabihf

    export CROSS_COMPILE=$CROSS
    export TOOLCHAIN=${TOOLCHAIN_DIR}/bin
    export LIB_DIR=${TOOLCHAIN_DIR}/arm-none-linux-gnueabihf/libc/lib
    export PATH=$TOOLCHAIN:$PATH
::

# 编译
FPN_be$ ./build_vx.sh
```

----

## 升级到 NN6.4.11.2

### 下载 6.4.11.2 压缩包并一个个解压

```sh
# eureka/Spencer-file/NN64112/Verisilicon_SW_Unified_Driver_6.4.11.2_Amlogic_20220719

tar xzf Verisilicon_SW_Unified_Driver_6.4.11.2_Amlogic_20220719.tgz
```

- 一个个解压并拷贝

- git commit 

**注意顺序**

```sh
mkdir Vivante_GALVIP_Unified_Src_drv_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_6.4.11.2
mv Vivante_GALVIP_Unified_Src_drv_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/

mkdir Vivante_GALVIP_Unified_Src_drv_AMLOGIC_GCFeature-addon_6.4.11.2.org & tar -zxf Vivante_GALVIP_Unified_Src_drv_AMLOGIC_GCFeature-addon_6.4.11.2.org.tgz -C Vivante_GALVIP_Unified_Src_drv_AMLOGIC_GCFeature-addon_6.4.11.2.org
cp Vivante_GALVIP_Unified_Src_drv_AMLOGIC_GCFeature-addon_6.4.11.2.org/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_AMLOGIC_GCFeature-addon_6.4.11.2.org/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_amlogic-platform-addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_amlogic-platform-addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_amlogic-platform-addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_amlogic-platform-addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_amlogic-platform-addon_6.4.11.2/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_AMLOGIC-prebuilt-addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_AMLOGIC-prebuilt-addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_AMLOGIC-prebuilt-addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_AMLOGIC-prebuilt-addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_AMLOGIC-prebuilt-addon_6.4.11.2/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_android-addon_6.4.11.2.noGPL.org & tar -zxf Vivante_GALVIP_Unified_Src_drv_android-addon_6.4.11.2.noGPL.org.tgz -C Vivante_GALVIP_Unified_Src_drv_android-addon_6.4.11.2.noGPL.org
cp Vivante_GALVIP_Unified_Src_drv_android-addon_6.4.11.2.noGPL.org/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_android-addon_6.4.11.2.noGPL.org/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_OCL-addon_6.4.11.2.noGPL & tar -zxf Vivante_GALVIP_Unified_Src_drv_OCL-addon_6.4.11.2.noGPL.tgz -C Vivante_GALVIP_Unified_Src_drv_OCL-addon_6.4.11.2.noGPL
cp Vivante_GALVIP_Unified_Src_drv_OCL-addon_6.4.11.2.noGPL/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_OCL-addon_6.4.11.2.noGPL/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_OVX-addon_6.4.11.2.noGPL & tar -zxf Vivante_GALVIP_Unified_Src_drv_OVX-addon_6.4.11.2.noGPL.tgz -C Vivante_GALVIP_Unified_Src_drv_OVX-addon_6.4.11.2.noGPL
cp Vivante_GALVIP_Unified_Src_drv_OVX-addon_6.4.11.2.noGPL/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_OVX-addon_6.4.11.2.noGPL/* -r


mkdir Vivante_GALVIP_Unified_Src_drv_OVXLIB-addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_OVXLIB-addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_OVXLIB-addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_OVXLIB-addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_OVXLIB-addon_6.4.11.2/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0XA1_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0XA1_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0XA1_VXC_addon_6.4.11.2
rm Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0XA1_VXC_addon_6.4.11.2/* -r


mkdir Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XBE_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XBE_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XBE_VXC_addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XBE_VXC_addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XBE_VXC_addon_6.4.11.2/* -r

mkdir Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XE8_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XE8_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIP9000NANODI_PID0XE8_VXC_addon_6.4.11.2

 mkdir Vivante_GALVIP_Unified_Src_drv_VIP9000NANOSI_PID0XB9_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIP9000NANOSI_PID0XB9_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIP9000NANOSI_PID0XB9_VXC_addon_6.4.11.2
 cp Vivante_GALVIP_Unified_Src_drv_VIP9000NANOSI_PID0XB9_VXC_addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
 rm Vivante_GALVIP_Unified_Src_drv_VIP9000NANOSI_PID0XB9_VXC_addon_6.4.11.2/* -r


mkdir Vivante_GALVIP_Unified_Src_drv_VIP9000NANOS_PID0X1000000E_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIP9000NANOS_PID0X1000000E_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIP9000NANOS_PID0X1000000E_VXC_addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_VIP9000NANOS_PID0X1000000E_VXC_addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r

mkdir Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0X88_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0X88_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0X88_VXC_addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0X88_VXC_addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_VIPNANOQI_PID0X88_VXC_addon_6.4.11.2/* -r


mkdir Vivante_GALVIP_Unified_Src_drv_VIPPICO_V3_PID0X99_VXC_addon_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_drv_VIPPICO_V3_PID0X99_VXC_addon_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_drv_VIPPICO_V3_PID0X99_VXC_addon_6.4.11.2
cp Vivante_GALVIP_Unified_Src_drv_VIPPICO_V3_PID0X99_VXC_addon_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_VIPPICO_V3_PID0X99_VXC_addon_6.4.11.2/* -r

 mkdir Vivante_GALVIP_Unified_Src_drv_SPIRV-addon_6.4.11.2.noGPL & tar -zxf Vivante_GALVIP_Unified_Src_drv_SPIRV-addon_6.4.11.2.noGPL.tgz -C Vivante_GALVIP_Unified_Src_drv_SPIRV-addon_6.4.11.2.noGPL
cp Vivante_GALVIP_Unified_Src_drv_SPIRV-addon_6.4.11.2.noGPL/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_drv_SPIRV-addon_6.4.11.2.noGPL/* -r

mkdir Vivante_GALVIP_Unified_Src_kernel_6.4.11.2 & tar -zxf Vivante_GALVIP_Unified_Src_kernel_6.4.11.2.tgz -C Vivante_GALVIP_Unified_Src_kernel_6.4.11.2
cp Vivante_GALVIP_Unified_Src_kernel_6.4.11.2/* /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/ -r
rm Vivante_GALVIP_Unified_Src_kernel_6.4.11.2/* -r


git apply ../../Spencer-file/NN64112/Verisilicon_SW_Unified_Driver_6.4.11.2_Amlogic_20220719/patch/0001-platform-patch-of-6.4.11.2-for-AMLOGIC.patch
git add Android.mk
git add Android.mk.def
git add config
git add hal/inc/gc_hal_options.h
git add hal/kernel/inc/gc_hal_options.h
git add hal/os/linux/kernel/allocator/default/gc_hal_kernel_allocator_gfp.c
git add hal/user/gc_hal_user_profiler.c


# commit:
Import from 0001-platform-patch-of-6.4.11.2-for-AMLOGIC.patch

Bug: None
Test: None
```


#### build

- 在这里去找 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/configs/amlogic/arch_a6432_10.3_7.3.1.config  应用所用的编译器 和 kernel 的编译器。

- NN 用 kernel 一样的，FPN_be 用 userspace 一样的

- 拷贝 build_ml.sh 和 acuity-ovxlib-dev/build_vx.sh 

- 修改 TOOLCHAIN 和 kernel


- 修改 hal/os/linux/kernel/platform/amlogic/gc_hal_kernel_platform_amlogic.c

- 编译

```sh
./build_ml.sh arm64 spencer-p2 ./../../chrome
```

- 编译模型

```sh
FPN_be$ ./build_vx.sh 
```

- 报错 errror

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon-6.4.11.2/build/sdk/drivers/libOpenVX.so: file not recognized: file format not recognized
```

### 在 av400 上测试

```
rmmod galcore
insmod ./data/galcore.ko showArgs=1
```

### 下载 actuity tool

#### 到 linux 上重新编译 NN case

**ubuntu 中编译 acuity-toolkit-binary**

```sh
# 解压出来的目录
~/NN/64112/acuity-toolkit-binary-6.9.0

/home/amlogic/NN/64112/acuity-toolkit-binary-6.9.0/google_test_model/FPN
```

- FPN_01.sh FPN

```sh
!/bin/bash

pegasus_bin=../../bin/pegasus
NAME=$1

if [ ! -e "$pegasus_bin" ]; then
    pegasus_bin=../../bin/pegasus.py
fi

$pegasus_bin import tflite \
        --model tflite_graph.tflite \
        --output-data ${NAME}.data \
        --output-model ${NAME}.json
```

- FPN_02.sh FPN

```sh
#!/bin/bash

pegasus_bin=../../bin/pegasus

NAME=$1
if [ ! -e "$pegasus_bin" ]; then
    pegasus_bin=../../bin/pegasus.py
fi

$pegasus_bin generate inputmeta \
        --model ${NAME}.json \
        --input-meta-output ${NAME}_inputmeta.yml
```

- 修改 FPN_inputmeta.yml

> https://docs.google.com/document/d/1JcOd5uLQAqdS8EtGSqvew1or_HZnDBiNP2-DE3C9zQ0/edit#


- FPN_03.sh FPN

```
#!/bin/bash

pegasus_bin=../../bin/pegasus
NAME=$1

if [ ! -e "$pegasus_bin" ]; then
    pegasus_bin=../../bin/pegasus.py
fi

$pegasus_bin quantize --quantizer asymmetric_affine \
        --qtype uint8 \
        --with-input-meta ${NAME}_inputmeta.yml \
        --model ${NAME}.json \
        --model-data ${NAME}.data \
        --rebuild
```


- FPN_04_a1.sh FPN

- FPN_04_be.sh FPN

> **这里需要修改对应的板子**    
> --optimize VIP9000NANOS_PID0X1000000E  #av400
> --optimize VIP9000NANODI_PID0XBE   #c2

```sh
#!/bin/bash

pegasus_bin=../../bin/pegasus
NAME=$1

if [ ! -e "$pegasus_bin" ]; then
    pegasus_bin=../../bin/pegasus.py
fi

$pegasus_bin export ovxlib \
        --model ${NAME}.json \
        --model-data ${NAME}.data \
        --model-quantize ${NAME}.quantize \
        --with-input-meta ${NAME}_inputmeta.yml \
        --dtype quantized \
        --optimize VIP9000NANOS_PID0X1000000E \
        --viv-sdk /home/amlogic/VeriSilicon/VivanteIDE5.6.0/cmdtools/ \
        --output-path ${NAME}/ \
        --pack-nbg-unify

        #--optimize VIP9000NANODI_PID0XBE \

mv ${NAME}_nbg_unify ${NAME}_be
mv ${NAME}_be/network_binary.nb ${NAME}_be/${NAME}_be.nb
```

- step4_inference.sh FPN

```sh
#!/bin/bash

NAME=$1
pegasus_bin=../../bin/pegasus

if [ ! -e "$pegasus_bin" ]; then
    pegasus_bin=../../bin/pegasus.py
fi

$pegasus_bin inference \
        --dtype quantized \
        --model ${NAME}.json \
        --model-data ${NAME}.data \
        --with-input-meta ${NAME}_inputmeta.yml
```

- 清除所有中间文件


bash clean.sh FPN

- 测试方法

```sh
bash step1.sh FPN 
vim FPN_inputmeta.yml 
bash step2.sh FPN
vim FPN_04_be.sh   # 修改成对应的板子
bash step3.sh FPN
 bash step4_inference.sh FPN 
```

---

### 测试模型

#### ssd_small_multiout_be

```sh
/data/ssd_small_multiout_be # ./tflite ./ssd_small_multiout_be.nb iter_0_input_0 
_out0_1_288_512_3.tensor
Create Neural Network: 14ms or 14604us 
Verify...
Verify Graph: 2ms or 2259us 
Start run graph [1] times... 
Run the 1 time: 4.20ms or 4199.62us 
vxProcessGraph execution time:
Total   4.30ms or 4303.92us
Average 4.30ms or 4303.92us
 --- Top5 ---
2719: 7162.175781
3103: 7162.175781
4255: 7162.175781
1567: 7021.740723
2335: 7021.740723

output0_12_32_18_1.dat
output10_24_1_1_1.dat
output11_546_1_1_1.dat
output1_273_32_18_1.dat
output2_24_16_9_1.dat
output3_546_16_9_1.dat
output4_24_8_5_1.dat
output5_546_8_5_1.dat
output6_24_4_3_1.dat
output7_546_4_3_1.dat
output8_24_2_2_1.dat
output9_546_2_2_1.dat
```

#### FPN

```sh
/data/FPN # ./tflite ./FPN_be.nb ./iter_0_input_0_out0_1_640_640_3.tensor
#productname=VIP9000Nano-S, pid=0x1000000e 
graph gpuCount=1 interConnectRingCount=0
NN ring buffer is disabled
Create Neural Network: 55ms or 55517us 
Verify...
vxoGraph_InitializeAllNodeKernels:22238, graph: 0x102c928, count: 1 
generate command buffer, total device count=1, core count per-device: 1,
binaryGenerateStatesBuffer:7067 current device id=0
binaryGenerateStatesBuffer:7068 VIP SRAM base address=0x400000 physical=0x40aa00 size=0x35600
binaryGenerateStatesBuffer:7069 AXI SRAM base address=0x0 physical=0x0 size=0x0
vxoBinaryGraph_CheckInputOutputParametes[3851]: tensor shape doesn't matched. index = 8, NBG shape: 24 5 5 1 , run time shape: 24 80 80 1
tp patch output failed, please check your output format, output 8
fail to initial memory in generate states buffer
fail in import kernel from file initializer
Failed to initialize Kernel "FPN_be" of Node 0x1049a78 (status = -1)
E [main.c:vnn_VerifyGraph:91]CHECK STATUS(-1:A generic error code, used when no other describes the error.)
E [main.c:main:240]CHECK STATUS(-1:A generic error code, used when no other describes the error.)
```

#### alexnet_caffe

```sh
/data/alexnet_caffe # ./tflite ./alexnet_caffe_be.nb ./space_shuttle.jpg
Create Neural Network: 55ms or 55621us
Verify Graph: 1ms or 1541us
Start run graph [1] times... 
Total segments: 1.
Run segment 0. Type: 1, operations: [1, 46].
Segment 0 submited.
Run the 1 time: 5.98ms or 5975.17us 
vxProcessGraph execution time:
Total   6.05ms or 6048.79us
Average 6.05ms or 6048.79us
 --- Top5 ---
812: 0.954590
404: 0.024567
895: 0.005264
908: 0.003252
565: 0.002954
```

#### googlenet_caffe

差距很大

```sh
/data/googlenet_caffe_be # ./tflite ./googlenet_caffe_be.nb ./goldfish_224x224.j 
peg
Create Neural Network: 18ms or 18343us 
Verify...
Verify Graph: 1ms or 1487us
Start run graph [1] times... 
Run the 1 time: 8.02ms or 8019.38us 
vxProcessGraph execution time:
Total   8.10ms or 8102.88us
Average 8.10ms or 8102.88us
 --- Top5 ---
  1: 0.999512
124: 0.000121
963: 0.000121
 27: 0.000096
122: 0.000068
```

#### mobilenetv1

```sh
/data/mobilenetv1 # ./tflite ./mobilenetv1_be.nb goldfish_224x224.jpeg
Create Neural Network: 15ms or 15948us 
Verify...
Verify Graph: 1ms or 1590us 
Start run graph [1] times... 
Run the 1 time: 3.86ms or 3862.96us 
vxProcessGraph execution time:
Total   3.95ms or 3949.04us
Average 3.95ms or 3949.04us
 --- Top5 ---
  1: 14.733068
115: 11.277164
925: 9.003542
 29: 8.275983
117: 8.275983


/data/mobilenetv1 # ./tflite ./mobilenetv1_be.nb iter_0_data_0_out0_1_3_224_224. 
tensor
Create Neural Network: 16ms or 16642us 
Verify...
Verify Graph: 1ms or 1547us 
Start run graph [1] times... 
Run the 1 time: 3.83ms or 3830.00us 
vxProcessGraph execution time:
Total   3.92ms or 3916.33us
Average 3.92ms or 3916.33us
 --- Top5 ---
  1: 14.733068
115: 10.913383
925: 8.912597
 29: 8.094093
117: 8.094093
```

#### yolov2

> 有点差距

```
/data/yolov2 # ./tflite ./yolov2_be.nb space_shuttle_416x416.jpg
Create Neural Network: 42ms or 42236us 
Verify...
Verify Graph: 1ms or 1949us 
Start run graph [1] times... 
Run the 1 time: 30.51ms or 30513.04us 
vxProcessGraph execution time:
Total   30.60ms or 30600.83us
Average 30.60ms or 30600.83us
 --- Top5 --- 
2311: 10.914330
2312: 10.412522
2313: 10.412522
1283: 9.910713
2128: 9.785261

/data/yolov2 # ./tflite ./yolov2_be.nb iter_0_input_0_out0_1_3_416_416.tensor
Create Neural Network: 42ms or 42444us 
Verify...
Verify Graph: 2ms or 2040us 
Start run graph [1] times... 
Run the 1 time: 30.45ms or 30446.79us 
vxProcessGraph execution time:
Total   30.53ms or 30533.46us
Average 30.53ms or 30533.46us
 --- Top5 --- 
2311: 10.914330
2313: 10.412522
1283: 10.287070
2312: 10.287070
1284: 9.910713
```

#### inceptionv1

```
/data/inceptionv1 # ./tflite inceptionv1_be.nb ./goldfish.jpeg
Create Neural Network: 17ms or 17803us 
Verify...
Verify Graph: 1ms or 1472us
Start run graph [1] times... 
Run the 1 time: 6.38ms or 6376.12us 
vxProcessGraph execution time:
Total   6.46ms or 6460.88us
Average 6.46ms or 6460.88us
 --- Top5 ---
  2: 0.884766
928: 0.053040
116: 0.012253
869: 0.005085
  1: 0.003000
/data/inceptionv1 # ./tflite inceptionv1_be.nb ./iter_0_input_1_out0_1_224_224_3 
.tensor
Create Neural Network: 18ms or 18603us 
Verify...
Verify Graph: 1ms or 1532us 
Start run graph [1] times... 
Run the 1 time: 6.37ms or 6367.71us 
vxProcessGraph execution time:
Total   6.44ms or 6440.46us
Average 6.44ms or 6440.46us
 --- Top5 ---
  2: 0.882324
928: 0.049896
116: 0.016373
869: 0.004780
964: 0.004009
```

#### ssd_mobilenet_v1

参考 6.4.0.12 修改 vnn_.c output 文件顺序

```sh
/data/ssd_mobilenet_v1 # ./tflite ssd_mobilenet_v1_be.nb iter_0_input_0_out0_1_3 
00_300_3.tensor
#productname=VIP9000Nano-S, pid=0x1000000e 
graph gpuCount=1 interConnectRingCount=0
NN ring buffer is disabled
Create Neural Network: 19ms or 19578us 
Verify...
vxoGraph_InitializeAllNodeKernels:22238, graph: 0x14a9928, count: 1
generate command buffer, total device count=1, core count per-device: 1,
binaryGenerateStatesBuffer:7067 current device id=0
binaryGenerateStatesBuffer:7068 VIP SRAM base address=0x400000 physical=0x40aa00 size=0x35600
binaryGenerateStatesBuffer:7069 AXI SRAM base address=0x0 physical=0x0 size=0x0
vxoBinaryGraph_CheckInputOutputParametes[3851]: tensor shape doesn't matched. index = 5, NBG shape: 24 1 1 1 , run time shape: 546 5 5 1
tp patch output failed, please check your output format, output 5
fail to initial memory in generate states buffer
fail in import kernel from file initializer
Failed to initialize Kernel "ssd_mobilenet_v1_b" of Node 0x14d3118 (status = -1)
E [main.c:vnn_VerifyGraph:91]CHECK STATUS(-1:A generic error code, used when no other describes the error.)
E [main.c:main:240]CHECK STATUS(-1:A generic error code, used when no other describes the error.)
'

/data/ssd_small_multiout_be # ./tflite ./ssd_mobilenet_v1_be.nb iter_0_input_0_o
ut0_1_288_512_3.tensor
Create Neural Network: 18ms or 18898us
Verify...
Verify Graph: 3ms or 3168us
Start run graph [1] times...
Run the 1 time: 8.70ms or 8702.71us
vxProcessGraph execution time:
Total   8.79ms or 8791.00us
Average 8.79ms or 8791.00us
 --- Top5 ---
3646: 4.105077
3190: 3.442968
3418: 3.442968
1594: 3.376757
1822: 3.310546
```

#### ssd_big_multiout

```sh
/data/ssd_big_multiout # ./tflite ./ssd_big_multiout_be.nb ./iter_0_input_0_out0 
_1_448_800_3.tensor
Create Neural Network: 17ms or 17738us 
Verify...
Verify Graph: 3ms or 3859us
Start run graph [1] times... 
Run the 1 time: 13.61ms or 13611.79us 
vxProcessGraph execution time:
Total   13.70ms or 13698.42us
Average 13.70ms or 13698.42us
 --- Top5 --- 
1243: 13279.916992
1843: 13279.916992
2443: 13279.916992
3043: 13279.916992
3643: 13279.916992
```

## verisilicon 6.4.11.2

创建 issue ： https://partnerissuetracker.corp.google.com/issues/263204650

自己的文档总结： https://docs.google.com/document/d/12e76aVCW-EFLc9Bgydmmnozzui3B4dJ2Pbe0UqcomLk/edit#




```sh
cd /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon

git fetch

 git branch -a | grep 6.4.11.2

git checkout -t eureka-partner/6.4.11.2
```

将 verisilicon-6.4.11.2 reset 到某个 commit，然后 cp 到 verisillicon 

```sh
verisilicon-6.4.11.2$ cp * ../verisilicon/ -r
```

- commit 记录

```
commit id: 8a27f8e77b34bb9038b380e735efba5e8aeb374d
git push eureka-partner HEAD:refs/for/6.4.11.2
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273125


ce449d3a4270fbcbcb36f5535386de79bb9af813
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273126

2db679f0b70fcedce2d2ff6e77bea7a0ff6d980c
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273127

ffb25035e0eb2f5b72e06d02a5657424ab95a010
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273128

e21d4752a88d38ae2bc5550d4b64f1302a926c1d
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273129

1278df1fdb0211e68d45a4bb769b8975d682c0b1
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273130

6a50db267a81d5b2a00b119ed58ad86639072085
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273132

8cce94d9b300f16c307ad012ded564a3d56a2744
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273145

3a6ea5ffea6b29cdd8791da6b589e9ee0fd5f552
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273148

da8226c744a93f182aec94d71b133b408dae643f
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273149

573822c01dcdfc336822f8b8bcc1f0ef6ed0d464
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273150

cb5f2276a876dc60177dd1451e99b14e7fddf2b1
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273151

3f99ee5d9dc42148292b689b2ee00127fe13ef6f
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273152

79d3eac21c1ba5ad8b862b62dd0bc0d34d1ec6fe
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273153

922eb66ded509ea6b3cb0adcdb97c698f92b69e7
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273154

f0ac9f088431fbbd3cb1c685d706c48aa3770dff
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273155

03d82e229df22efdfe853031ef06ce0bb5fe7ec0
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273156

abd8d26d7ae7d37966f17f0923a389ac54a126a4
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273157

07ec1e746e65e89176b001691417bb28605969c4
https://eureka-partner-review.googlesource.com/c/verisilicon-sdk/+/273158
```

- 所有的 topic cls : https://eureka-partner-review.googlesource.com/q/topic:%22verisilicon-6.4.11.2%22
- 给 google 的文档：https://docs.google.com/document/d/1JTUCzPwTrY9xw1cA3fbS8vDJmZ5PMTw6JBZGAIk51Ts/edit#



- 回复 issue

Hi Jamie,

The Verisilicon 6.4.11.2 Driver has been released, And I have verified it with google_test_model. Here is Verisilicon Driver 6.4.11.2 AML Release Note

```
https://docs.google.com/document/d/1JTUCzPwTrY9xw1cA3fbS8vDJmZ5PMTw6JBZGAIk51Ts/edit?usp=share_link
```

Here is all CLs: 

```
https://eureka-partner-review.googlesource.com/q/topic:%22verisilicon-6.4.11.2%22
```

In addition, the kernel and toolchain I used to compile galcore.ko are respectively: `kernel5.4 & gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu`


The toolchain used to compile the related lib so is: `gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf `

And I have attached my compile script, please check: build_ml.sh & acuity-ovxlib-dev/build_vx.sh




- 回复邮件

Hi Jamie,

The Verisilicon 6.4.11.2 Driver has been released, And I have verified it with google_test_model, you can also review by this doc,

https://docs.google.com/document/d/1JTUCzPwTrY9xw1cA3fbS8vDJmZ5PMTw6JBZGAIk51Ts/edit#

Here is all CLs,

https://eureka-partner-review.googlesource.com/q/topic:%22verisilicon-6.4.11.2%22

By the way, you can also check this issue for more details,

https://partnerissuetracker.corp.google.com/issues/263204650

Thanks 