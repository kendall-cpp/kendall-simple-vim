# Korlan

## 实现根据 i2s 时钟检查 Enable/Disable Codec功能

> https://partnerissuetracker.corp.google.com/issues/236912216

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247301

## fix fct-korlan 无法找到 ip 

> issue: https://partnerissuetracker.corp.google.com/issues/247080714

- 解决方法

- 打开 CONFIG_USB_RTL8152=y

```sh
# vim arch/arm64/configs/korlan-p2_defconfig
CONFIG_USB_RTL8152=y
```

- 动态获取需要启动 hdcpcd 服务

如果要开机就启动 dhcpcd 服务，需要在 init.rc 中添加 `start dhcpcd`

USB 需要设置成 host 模式

```sh
# 第一种返回时
echo 1 > /sys/kernel/debug/usb_mode/mode  

# 第二种方式
fts -s usb_controller_type  host
reboot
```

korlan 中是用 `ifconfig -a` 命令查看 ip

### chrome 单独编译一个模块

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/adb

mma PARTNER_BUILD=true

# test
echo 0 > /sys/kernel/debug/usb_mode/mode
```

### 提交

```sh
git push eureka-partner HEAD:refs/for/korlan-master

# 需要关注
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/260551
commit id: 7ef11940e2f980a3e10243fce1cdb87cd80cf1d6
```

## fix adb connect 被拒绝问题 

adb connect 默认是使用 IPV6 进行连接的，所以需要在 kernel 中开启 IPV6，开启方式需要在 make menuconfig 中开启。

- 可能会出现编译出错

```c
make: *** [Makefile:1159: net] Error 2
make: *** Waiting for unfinished jobs....
Fatal error: script ./build_kernel.sh aborting at line 54, command "make CLANG_TRIPLE=$clang_triple CC=$cc_clang CROSS_COMPILE=$1 ARCH=$3 -j$2 $4 CONFIG_DEBUG_SECTION_MISMATCH=y" returned 2
```

解决方法是修改 `include/linux/ipv6.h`

```c
+	__s32		accept_ra_rt_table;
	__s32		proxy_ndp;
	__s32		accept_source_route;
	__s32		accept_ra_from_local;
```

- 测试

使用 netstat 命令查看有没有监听 5555 端口

启动 start adbd-secure / start adbd

- 遇到能 adb connect ip:5555 , 但是不能 adb shell 问题

这可能是编译的 adb-secure 的问题，可以重新编译 adb-secure 并替换 ramdisk 中 sbin/adb-secure

- 编译方法

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core
#vim libcutils/socket_inaddr_any_server_unix.cpp
# 修改 socket ipv4 [adb 默认是ipv6]

cd abd
mma PARTNER_BUILD=true
```


## kernel 裁剪

- yuegui 裁剪 patch
  
```sh
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/268825

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/268826
```

```sh
# Device Drivers  ---> SCSI device support  ---> SCSI device support
#  < > VFAT (Windows-95) fs support 
# Device Drivers  ---> --- Network device support  <*>   USB Network Adapters  --->  直接全部关闭 Multi-purpose USB Networking Framework
```

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/270868
```

## 实现 aplay 和 uac 同时播放冲突问题

https://partnerissuetracker.corp.google.com/issues/262352934

 给 tdm 增加一个 busy 状态，当 aplay 播放时， uac 等待 aplay 播放结束

 修复的 cl: https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/275167


## koraln 增加 erofs 支持

chrome 文件系统制作脚本 Vota_from_target_files

topic: https://eureka-partner-review.googlesource.com/q/topic:%22Enable+erofs%22

```sh
# common_drivers
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276586

# kernel-5.15
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276587

# u-boot
https://eureka-partner-review.googlesource.com/c/amlogic/u-boot/+/276588

# vendor/amlogic
https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/276589
```


## 迁移 tdm_bridge 功能到 kernel 5.4

### AV400 buildroot 测试 UAC

https://scgit.amlogic.com/293851

### AV400 kernel-5.4 打开 UAC

https://scgit.amlogic.com/#/c/293855/

### 修改 功放板 patch

Change power amplifier driver board from D622 to D613

https://scgit.amlogic.com/#/c/292999/

#### 修改 UAC 模式支持 window

https://scgit.amlogic.com/29845


### 解决 tdm_bridge underrun 问题

#### 声音播放延迟问题

这个判断回合 channel 有关，

```c
a5 tx_mask must be 0x03 aml_tdm_br_hw_setting(tdm, 2);  //a5 ch = 2

korlan ch = 1
```

####  src-clk-freq 不对导致偶尔会出现 underrun 问题

tdm_bridge 偶尔会出现 underrun 问题，肯定是和 clk 有关，对应的代码

```c
//aml_tdm_platform_probe
ret = of_property_read_u32(dev->of_node, "src-clk-freq", &p_tdm->syssrc_clk_rate);

//mclk 和 clk 的值不同芯片不一样
clk_set_rate(tdm->mclk, mclk);  // 对应设备树种的 src-clk-freq，
// a5 491520000 a1 614400000

clk_set_rate(tdm->clk, mpll_freq);  //从 seeting->sysclk 中过来
```

- 修改设备树

```sh
--- a/arch/arm64/boot/dts/amlogic/a5_a113x2_av400_1g_spk.dts
+++ b/arch/arm64/boot/dts/amlogic/a5_a113x2_av400_1g_spk.dts
@@ -508,7 +508,7 @@
                start_clk_enable = <1>;
                tdm5v-supply = <&vcc5v_reg>;
                tdm3v3-supply = <&vddio3v3_reg>;
-               src-clk-freq = <614400000>;
+               src-clk-freq = <491520000>; /*mpll1 mclk is 491520000*/
                status = "okay";
        };
```

#### 如果有一点点杂音

那可能是与 aml_frddr_set_fifos 或者 dma_buf->bytes 设置不对有关。


### 添加 timestamp 模块

- 修改dts

```sh
                channel_mask = <0x3>;
                status = "disabled";
        };
+       timestamp {
+               compatible = "amlogic, meson-soc-timestamp";
+               reg = <0x0 0xFE0100EC 0x0 0x8>;
+               status = "okay";
+       };
 }; /* end of audiobus */


+CONFIG_AMLOGIC_SOC_TIMESTAMP=y
```

- 修改 Kconfig 和 Makefile

```sh
diff --git a/drivers/amlogic/Kconfig b/drivers/amlogic/Kconfig
index 3208df21ec95..5daaa5be6709 100644
--- a/drivers/amlogic/Kconfig
+++ b/drivers/amlogic/Kconfig
@@ -177,6 +177,7 @@ source "drivers/amlogic/freertos/Kconfig"
 
 source "drivers/amlogic/aes_hwkey_gcm/Kconfig"
 source "drivers/amlogic/gpio/Kconfig"
+source "drivers/amlogic/timestamp/Kconfig"
 
 endmenu
 endif
diff --git a/drivers/amlogic/Makefile b/drivers/amlogic/Makefile
index 6226bc7b43b3..fba5e8d7b264 100644
--- a/drivers/amlogic/Makefile
+++ b/drivers/amlogic/Makefile
@@ -39,6 +39,7 @@ obj-$(CONFIG_AMLOGIC_MKL)             += mkl/
 
 #Always build in code/modules
 obj-$(CONFIG_AMLOGIC_CPUIDLE)          += cpuidle/
+obj-$(CONFIG_AMLOGIC_SOC_TIMESTAMP) += timestamp/
 obj-$(CONFIG_AMLOGIC_DEFENDKEY)                += defendkey/
 obj-$(CONFIG_AMLOGIC_AUTO_CAPTURE)     += free_reserved/
 obj-$(CONFIG_AMLOGIC_GX_SUSPEND)       += pm/
diff --git a/drivers/amlogic/timestamp/Kconfig b/drivers/amlogic/timestamp/Kconfig
new file mode 100644
index 000000000000..488faae454a2
--- /dev/null
+++ b/drivers/amlogic/timestamp/Kconfig
@@ -0,0 +1,8 @@
+# SPDX-License-Identifier: GPL-2.0-only
+config AMLOGIC_SOC_TIMESTAMP
+       bool "Amlogic SoC Timestamp"
+       depends on ARCH_MESON || COMPILE_TEST
+       depends on OF
+       default y
+       help
+         Say yes if you want to get soc-level timestamp.
```

- 从 kernel 5.15 拷贝 drivers/amlogic/timestamp

-----

# Elaine

## 以太网压力测试问题 【Done】

> https://partnerissuetracker.corp.google.com/issues/246404063  

触摸屏驱动影响了 USB 以太网，在不停重启压力测试时，会出现找不到 eth0 问题。

### 解决方法--推迟goodix

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/255070

```c
// vim drivers/input/touchscreen/goodix_touch_gtx8/goodix_ts_i2c.c
- module_init(goodix_i2c_init);
+ late_initcall(goodix_i2c_init);
```

### 推迟 func3

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/259656
commitId: 6b7f44b5eed0a00ef73bb94dbf5c64551fdb40a9
```


### 根据 kernel patch 修复

- 讨论 (patch 链接在最后)：https://bugzilla.kernel.org/show_bug.cgi?id=214021

#### bug 解决总结

在 xhci_plat_probe 里，两个重量级的函数是 usb_create_hcd 和 usb_add_hcd , 下面我们主要分析这两个函数。

```c
hcd = usb_create_hcd(driver, &pdev->dev, dev_name(&pdev->dev));  //创建一个usb_hcd结构体，并进行一些赋值操作， usb2.0
usb_create_shared_hcd()   //创建一个 usb_hcd 结构体，usb 3.0


// 在 USB 3.0 之后，两次执行 usb_add_hcd ，第一次只是 xhci_run （set_bit(HCD_FLAG_DEFER_RH_REGISTER, &hcd->flags);）, 
// 并没有去注册 hcd，也就是没有执行 register_root_hub
// 第二次 xhci_run --> xhci_run_finished 
// 接着 register_root_hub 两个 hcd（primary_hcd 和 share_hcd）
usb_add_hcd(hcd, irq, IRQF_SHARED);  
usb_add_hcd(xhci->shared_hcd, irq, IRQF_SHARED) 

//最后通过这个函数去通知 hub。这个函数 会一直使用定时器调用自己，如果读取到 hub 有变化，而且有提交的 urb，就返回。
usb_hcd_poll_rh_status(hcd) 
//会面就会去对 hub_event 进行处理
```

同时需要注意 `#define HCD_FLAG_DEFER_RH_REGISTER     12` , kernel patch 中设置的是第 8 位 bit，但是在 elaine-kernel 的版本中第 8 位已经被占用，因此改成第 12 位，否则 usb2 的 hcd 永远无法 register 。


#### 最终提交

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/262595
commit id : 934882f98b37c0485de4850f7f1f7001d6c3c269
issue: https://partnerissuetracker.corp.google.com/issues/246404063#comment2
```

---


---

# AV400 NN 模型测试

> https://jira.amlogic.com/browse/GH-3183

## 修改 vsi 编译工具和kernel地址

```sh
参考 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/hardware/aml-5.4/npu/nanoq 下面的文件
aml_buildroot.sh makefile.linux 
修改 build_ml.sh acuity-ovxlib-dev/build_vx.sh
具体修改见附件文件：`NN-av400-arm64-gc_hal_kernel_platform_amlogic.patch`
```

### 对应 buildroot 配置文件

```sh
在这里去找 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/configs/amlogic/arch_a6432_10.3_7.3.1.config  应用所用的编译器 和 kernel 的编译器
vim package/amlogic/npu/npu.mk  找编译 npu 的编译脚本

 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/configs/amlogic/npu_driver_k5.4.config 
  这里会配置一下全局的局部变量，给 package/amlogic 下的各个 package 用
 比如给 package/amlogic/npu/npu.mk 使用
```

## 编译 verisilicon

```sh
cd verisilicon
./build_ml.sh arm64 spencer-p2 ./../../chrome
```


### 关于 so lib Errro

- error log


- 编译报错

```sh
/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/aarch64/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/../lib/gcc/aarch64-linux-gnu/7.3.1/../../../../aarch64-linux-gnu/bin/ld: cannot find -lVSC
/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/aarch64/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/../lib/gcc/aarch64-linux-gnu/7.3.1/../../../../aarch64-linux-gnu/bin/ld: cannot find -lCLC
/mnt/fileroot/shengken.lin/workspace/a5_buildroot/toolchain/gcc/linux-x86/aarch64/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/../lib/gcc/aarch64-linux-gnu/7.3.1/../../../../aarch64-linux-gnu/bin/ld: cannot find -lSPIRV_viv
collect2: error: ld returned 1 exit status

build/sdk/drivers/libCLC.so, not found (try using -rpath or -rpath-link)
sdk/drivers/libArchModelSw.so, not found (try using -rpath or -rpath-link)
```

- 这是由于编译器 FIXED_ARCH_TYPE 没选择对

修改编译脚本 `build_aml.sh` 和 `acuity-ovxlib-dev/build_vx.sh `

```sh
export FIXED_ARCH_TYPE=aarch64-gnu
```

> 具体参考

- 另外 build/sdk/driver 下的 so 是直接 compiler 下复制的过去的，见如下代码调试


```sh
# verisilicon/compiler/libVSC/makefile.linux  
284 cpfile:                       
285     @-cp -f $(FIXED_ARCH_TYPE)/$(TARGET_NAME) $(INSTALL_DIR)   
# cp -f arm64/libVSC.so /mnt/fileroot/shengken.lin/workspace/google_source/eureka/spencer-sdk/verisilicon/build/sdk/drivers 
```


### insmod galcore 时 error

```sh
# insmod /data/galcore.ko

# error
[   85.209473@0]  Unable to handle kernel read from unreadable memory at virtual address ffffff82bd534b30
[  113.222304@2]  Unable to handle kernel read from unreadable memory at virtual address ffffff8a7d534b30
```

如果出现类似上面的 error，就是 clock 没正确释放

```c
npu_core_clk = devm_clk_get(&pdev->dev, "cts_vipnanoq_core_clk_composite");
//clk_put(npu_core_clk);
static void put_clock(struct platform_device *pdev)
// 具体见 av400-NN.patch
```

> **以上修改的 patch: NN-av400-arm64-arm32-all.patch**

## 测试 case 错误

> **模型测试文件系统32位于64位对不上问题**

- error log

```sh
/data/FPN # ./tflite ./FPN_be.nb ./iter_0_input_0_out0_1_640_640_3.tensor
/bin/sh: ./tflite: not found
```

> -  因此需要将  case 都编译成 arm32 位的
> - verisilicon 仍然是 64 位
> - 参考：a5_buildroot/buildroot/configs/amlogic/arch_a6432_10.3_7.3.1.config


### 最终编译 verisilicon-arm32 

- 编译 ddk

```sh
./build_ml.sh arm64 spencer-p2 ./../../chrome
```

目前位置的 patch: NN-av400-arm64-arm32-all.patch

## 编译和测试 verisilicon-6.4.11.2

修改的 gc_hal_kernel_platform_amlogic.c 见附件：NN-av400-arm64-verisilicon-6.4.11.2-gc_hal_kernel_platform_amlogic.patch

- 编译 verisilicon-6.4.11.2 获得 galcore.ko

```sh
./build_ml.sh arm64 spencer-p2 ./../../chrome
```

- 去掉 kernel 路径编译获得 so

```sh
./build_ml.sh arm32 spencer-p2 ./../../chrome
```

> build_ml.sh 参考 附件 

```sh
verisilicon-6.4.11.2/build/sdk/drivers
```

- 测试的时候需要将 verisilicon-6.4.11.2/build/sdk/drivers 下所有 so push 到 av400 的 /usr/lib/ 目录下

- 注意：**ubuntu 中编译 acuity-toolkit-binary** 时 FPN 和 ssd_mobilenet_v1 这两个 case 
  - 编译出来的 FPN_be 需要的 vnn_.c 需要参考 6.4.0.12 修改 vnn_.c output 文件顺序

```c
//修改大致这个范围
    graph->input.tensors[0] = norm_tensor[0];
    graph->output.tensors[0] = norm_tensor[1];
    graph->output.tensors[1] = norm_tensor[2];
    graph->output.tensors[2] = norm_tensor[3];
    graph->output.tensors[3] = norm_tensor[4];
    graph->output.tensors[4] = norm_tensor[5];
    graph->output.tensors[5] = norm_tensor[6];
    graph->output.tensors[6] = norm_tensor[7];
    graph->output.tensors[7] = norm_tensor[8];
    graph->output.tensors[8] = norm_tensor[9];
    graph->output.tensors[9] = norm_tensor[10]
```

**总结文档**：https://docs.google.com/document/d/12e76aVCW-EFLc9Bgydmmnozzui3B4dJ2Pbe0UqcomLk/edit?usp=sharing

- 所有的 topic cls : https://eureka-partner-review.googlesource.com/q/topic:%22verisilicon-6.4.11.2%22
- 给 google 的文档：https://docs.google.com/document/d/1JTUCzPwTrY9xw1cA3fbS8vDJmZ5PMTw6JBZGAIk51Ts/edit#

---

# C3 AW409 

MBP 理解和使用：https://confluence.amlogic.com/pages/viewpage.action?pageId=215566618

