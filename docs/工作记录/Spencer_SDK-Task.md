
- [NN模型转换](#nn模型转换)
  - [编译出 ssd_small_multiout_be.nb](#编译出-ssd_small_multiout_benb)
- [TASK: VSI 版本编译问题 bug](#task-vsi-版本编译问题-bug)
  - [复现测试](#复现测试)
    - [update kernel & uboot & system](#update-kernel--uboot--system)
    - [编译 spencer ota 包](#编译-spencer-ota-包)
    - [Replace bootloader](#replace-bootloader)
    - [无法通过reboot update 进入烧录模式](#无法通过reboot-update-进入烧录模式)
    - [测试问题](#测试问题)
      - [解决 adb 无法 push 问题](#解决-adb-无法-push-问题)
  - [更新 verisilicon 驱动](#更新-verisilicon-驱动)


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
insmod galcore.ko

./tflite ./alexnet_caffe_be.nb iter_0_input_0_out0_1_3
./tflite ./alexnet_caffe_be.nb ./space_shuttle.jpg 
```

- **转换输出文件为 txt**

修改 vnn_post_process.c

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

- 拷贝解压烧录

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



### 无法通过reboot update 进入烧录模式


更改模式

```sh
/ # cat /proc/fts 
fdr_count=17
reboot_mode=normal
encryption_salt=6719F51F524E847350B7A7CCDD23B09AC97A7332A2BB61DC4E5F5B7E29C2B841
bootloader.command=boot-factory
/ # fts -s bootloader.command 
/ # cat /proc/fts 
fdr_count=17
reboot_mode=normal
encryption_salt=6719F51F524E847350B7A7CCDD23B09AC97A7332A2BB61DC4E5F5B7E29C2B841
/ # 
```

关闭或者打开 factory boot    

```
vim cmd/amlogic/cmd_factory_boot.c     
vim cmd/amlogic/cmd_reboot.c  
```

### 测试问题

```sh
spencer-sdk/NN649/issue$ ../../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang++ main.cpp -o main.o -L ../../verisilicon/build/sdk/drivers -static -W1,--whole-archive -lovxlib
```

#### 解决 adb 无法 push 问题

修改kernel代码

```c
vim kernel/arch/arm64/boot/dts/amlogic/spencer-p2.dts 

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


- push 静态库

```sh
adb.exe push .\drivers\. /data/

# 还需要在这里把 Z:\windowFile\Spencer_SDK文件\NN649\issue\drive-download-20220905T020706Z-001 把 benchmark_model 和 libneural_network_models.so push 到 /data

push 

export LD_LIBRARY_PATH=/data:$LD_LIBRARY_PATH


# 声明环境变量 打印更多信息
export VIV_VX_DEBUG_LEVEL=1

./mynn ./mynn.export.data ./iter_0_input_0_out0_1_3_227_227.tensor 


# 测试module
VIV_VX_DEBUG_LEVEL=1 benchmark_model -m VsiCustomFpn
VIV_VX_DEBUG_LEVEL=1 benchmark_model
```



----


## 更新 verisilicon 驱动

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

---








