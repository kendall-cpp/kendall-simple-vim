# RTOS 运行在哪个 core

https://support.amlogic.com/issues/18567


Hi artie, 

Does AML have documentation on how to run RTOS on one core? We'd like to bring that up on the A113X2 EVM.

> You mean run rtos on arm or dsp or risc-v core? currently rtos run on rsic-v and hifi5 (DSP). 

Can you also share info on how the RTOS and Linux cores would boot? 

> For DSP, we run rtos Base on system via dsp_utils, 
> eg: dsp_util --load --dsp hifi4a -f /lib/firmware/dspbootA.bin


 Is it a simultaneous boot, does one O/S need to come up before the other, or can they boot independently (boot RTOS while other Linux A cores are still down)?

 > linux is running on ARM, RTOS is running on DSP, in addition, DSP running after linux, so it isn't a simultaneous boot, first boot linux, then load rtos.

Also, would the RTOS core need its own eMMC or can the same eMMC be partitioned for Linux and RTOS?

> RTOS is loaded on the linux, so RTOS doesn't need own EMMC

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

### 流程

main  -- vTaskStartScheduler

FreeRTOS是通过 vTaskStartScheduler() 函数来启动运行的

> freeRTOS的xTaskCreate与 xTaskCreateStatic的区别

xTaskCreate与 xTaskCreateStatic的功能上的区别是，xTaskCreate是操作系统自动分配内存，xTaskCreateStatic是需要程序员手动定义内存；

xTaskCreate适用于项目开发中内存余量比较充足的项目，只是简单的分配大小就可以了；
xTaskCreateStatic适用于项目开发中内存比较紧张的项目，事先定义好内存大小并占用内存空间，这样在系统编译的时候就可以确定总内存大小，也不会出现系统运行到当前任务时内存不足而出现崩溃的情况；

> https://blog.51cto.com/u_14970037/5623544


相关流程

- 在 bl30 阶段 启动 rtos

创建和调度任务

- 启动 uboot

- 启动 kernel

- 加载 hifi4dsp

以 driver 的形式加载。代码实现在下面的函数中

> kernel/aml-5.4/drivers/amlogic/hifi4dsp/hifi4dsp_module.c 


### rsic-v rtos 流程

首先创建一个 str 任务

hw_business_process  -  create_str_task

# JTAG 接口和 SWD 接口

https://support.amlogic.com/issues/18561

参考：https://support.amlogic.com/issues/12564#change-89466

## OpenOCD安装与使用（JTAG调试）

在 ubuntu 中

第一步： git clone https://github.com/openocd-org/openocd

