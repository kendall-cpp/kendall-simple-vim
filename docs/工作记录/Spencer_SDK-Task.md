
- [NN模型转换](#nn模型转换)
  - [编译出 ssd_small_multiout_be.nb](#编译出-ssd_small_multiout_benb)
- [TASK: VSI 版本编译问题 bug](#task-vsi-版本编译问题-bug)
  - [复现测试](#复现测试)
    - [update kernel & uboot & system](#update-kernel--uboot--system)
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
    - [烧录](#烧录)
    - [充电](#充电)


---



# NN模型转换

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

insmod galcore.ko

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

这里以NQ为例，为了方便开发，我们选择开发版本 nq-eng, 版本号选择  

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

···
cd kernel
./build_kernel.sh gq-b3 ./../../chrome 
cd -
···

#### isp module

```
cd lloyd-isp
./build_isp.sh nq-b3 ./../../chrome 
cd -
```

#### NN module

```sh
cd verisilicon
./build_ml.sh arm64 gq-b3 ./../../chrome 
cd -
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


### 充电


```sh
# 使用 nlspi_client 命令
# 参数 -fault_mode=<1 or 0>           Set/Clear battery fault mode
nlspi_client -fault_mode=0  #清除电池错误状态
logcat -s iot_power  # 查看充电状态
```













