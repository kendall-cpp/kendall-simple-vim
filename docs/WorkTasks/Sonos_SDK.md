# RTOS 运行在哪个 core

https://support.amlogic.com/issues/18567

## 熟悉 DSP 和 rsic-v 

- dsp 

/mnt/fileroot/shengken.lin/workspace/sonos-sdk/vendor/amlogic/rtos/HiFiDSP_rtos_sdk

-  Run on RISC-V cpu

/mnt/fileroot/shengken.lin/workspace/sonos-sdk/bootloader/uboot-repo/bl30/rtos_sdk

- 启动 dsp 脚本

```sh
vim buildroot/package/amlogic/aml-hifi-rtos-sdk/S71_load_dspa
# output/a5_av400_a6432_release/target$ cat etc/init.d/S71_load_dspa

dsp_util --load --dsp hifi4a -f dspbootA.bin

/lib/firmware/dspbootA.bin
```

**相关流程**

- 在 bl30 阶段 启动 rtos

创建和调度任务

- 启动 uboot

- 启动 kernel

- 加载 hifi4dsp

以 driver 的形式加载。代码实现在下面的函数中

> kernel/aml-5.4/drivers/amlogic/hifi4dsp/hifi4dsp_module.c 

## 研究a5-av400 supend 过程

使用 echo "mem" > /sys/power/state 进行测试，就会走整个流程

bootloader/uboot-repo/bl30/rtos_sdk/soc/riscv/a5/clk.c  

- vCLK_suspend  # 断电，rics-v rtos 进入休眠模式


kernel/aml-5.4/kernel/power/main.c

- state_store

kernel/aml-5.4/kernel/power/suspend.c 

- pm_suspend

vendor/amlogic/rtos/HiFiDSP_rtos_sdk/arch/xtensa/hificommon.c      

- vSuspendTask


## kernel suspend 流程

linux 中， pm_suspend 通过读取 state，

> 一些函数介绍参考： https://blog.csdn.net/weixin_42749767/article/details/83374105

```sh
pm_suspend # 这个函数是从 main.c state_store 调进来
        -- enter_state # 进入系统睡眠所需的公共准备工作
                -- suspend_prepare # 进入suspend的准备，包含选择控制台和进程冻结，如果失败，则终止suspend
                -- suspend_devices_and_enter # 对suspend和resume的所有实际操作
                        -- dpm_suspend_start # Suspend所有非系统设备，即调用所有注册设备的suspend回调函数
                                -- dpm_prepare  # 为系统 PM 转换准备所有非 sysdev 设备。
                                        -- wait_for_device_probe # 通过一个 wait_event 通知 device 对应的 porbe
                                -- dpm_suspend # 准备好之后执行所有设备的 suspend 回调函数
                                        -- device_suspend
                                                -- __device_suspend
                                                        -- dpm_run_callback  # 调用设备的回调函数，包括des_suspend
                                                                -- dsp_suspend #在 drivers/amlogic/hifi4dsp/hifi4dsp_module.c suspend dsp rtos

                                                                # 这里会与 bl31 通信并 suspend risc-v rtos
                                                                -- psci_system_suspend_enter # 这个是psci_suspend_ops的成员，在 psci_init_system_suspend 函数中被回调
                                                                        -- cpu_suspend
                                                                                -- psci_system_suspend  #和 BootLoader 通信；drivers/firmware/psci/psci.c 
```

> 分析的 patch: test-suspend-flow.patch

### psci  接口规范

psci 规定了 linux 内核调用 bl31 中电源管理相关服务的接口规范，它包含实现以下功能所需的接口：

- cpu idle管理
- 向系统动态添加或从系统动态移除 cpu，通常称为 hotplug
- secondary cpu 启动
- 系统的 shutdown 和 reset

psci 接口规定了命令对应的 function_id 、接口的输入参数以及返回值。 其中输入参数可通过 x0 – x7 寄存器传递，而返回值通过 x0 – x4 寄存器传递。

### 对于 HiFiDSP rots

> vendor/amlogic/rtos/HiFiDSP_rtos_sdk/arch/xtensa/hificommon.c   

```sh
vSuspendTask 
```


### 对于 risc-v

> bl30/rtos_sdk/drivers_aocpu/str/suspend.c  

```sh
create_str_task
        -- vSTRTask # 创建一个任务，执行 suspend 相关操作
                -- system_suspend # 系统休眠函数

```

kernel 通知 risc-v suspend 之后，进入 risc-v 的代码，主要是 vCLK_suspend 这个函数

bootloader/uboot-repo/bl30/rtos_sdk/soc/riscv/a5/clk.c  

```c
void vCLK_suspend(uint32_t st_f) 
xTransferMessageAsync(AODSPA_CHANNEL, MBX_CMD_SUSPEND_WITH_DSP, &xIdx, 4);
```

vCLK_suspend 是提供给 TFLPM 的接口。TFLPM 和 linux 之间建立联系


> **另外， ricsv/rtos 中 通过 mailbox 和 hifi5DSP rtos 通信**


----

# 验证sonos A113D ， xtest

参考jira https://jira.amlogic.com/browse/SWPL-84796

https://confluence.amlogic.com/pages/viewpage.action?pageId=225027291#Test&Tools-Xtest

https://optee.readthedocs.io/en/latest/building/gits/optee_test.html


## 烧录完成后编译进不去 kernel

- 进入 uboot

```sh
axg_s400_v1#imgread kernel boot 0x1080000

Error: malloc in  android_image_need_move failed!
ERROR: can't get kernel image!
```

- fix

改成比 boot.img 大才可以

```sh
@ken@:/mnt/fileroot/shengken.lin/workspace/sonos-axg/bootloader/uboot-2015-dev$ git diff
diff --git a/arch/arm/include/asm/arch-axg/cpu.h b/arch/arm/include/asm/arch-axg/cpu.h
index 4dc5c06911..3c4e0e3d43 100644
--- a/arch/arm/include/asm/arch-axg/cpu.h
+++ b/arch/arm/include/asm/arch-axg/cpu.h
@@ -30,7 +30,7 @@
 #define CONFIG_AML_MESON_AXG 1
 
 /* Size of malloc() pool */
-#define CONFIG_SYS_MALLOC_LEN          (11*1024*1024) /* 128M ddr support max 11M malloc */
+#define CONFIG_SYS_MALLOC_LEN          (13*1024*1024) /* 128M ddr support max 11M malloc */
```

## as400 修改分区大小

uboot-2015-dev/board/amlogic/axg_s400_v1/axg_s400_v1.c 

aml-4.9/arch/arm64/boot/dts/amlogic/axg_s400.dts  

```sh
--- a/board/amlogic/axg_s400_v1/axg_s400_v1.c
+++ b/board/amlogic/axg_s400_v1/axg_s400_v1.c
@@ -477,7 +477,7 @@ static struct mtd_partition normal_partition_info[] = {
     {
         .name = "boot",
         .offset = 0,
-        .size = 12*SZ_1M,
+        .size = 15*SZ_1M,
     },
```

## 最终测试 xtest 

https://jira.amlogic.com/browse/SWPL-110748