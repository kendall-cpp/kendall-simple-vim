
- [裸机程序](#裸机程序)
  - [开发环境的搭建](#开发环境的搭建)
    - [安装 NFS](#安装-nfs)
    - [CH340 驱动](#ch340-驱动)
    - [安装交叉编译器](#安装交叉编译器)
  - [汇编语言编写 LED 驱动](#汇编语言编写-led-驱动)
    - [编译驱动](#编译驱动)
    - [将板子连接到 PC](#将板子连接到-pc)
    - [makefile 的编写](#makefile-的编写)
  - [C 语言编写 LED 驱动](#c-语言编写-led-驱动)
    - [设置处理器模式](#设置处理器模式)
    - [设置 SP 指针](#设置-sp-指针)
    - [编译烧录](#编译烧录)
  - [stm32 模式编写LED驱动](#stm32-模式编写led驱动)
- [第三期 系统移植](#第三期-系统移植)
  - [烧写实验](#烧写实验)
    - [使用 OTG 烧写](#使用-otg-烧写)
    - [Ubuntu 脚本烧写](#ubuntu-脚本烧写)
  - [Uboot 编译和烧写](#uboot-编译和烧写)
  - [启动 Uboot 分析](#启动-uboot-分析)
    - [uboot 源码目录](#uboot-源码目录)
    - [uboot 启动流程](#uboot-启动流程)
  - [linux 内核移植](#linux-内核移植)
    - [编译 NXP 官方开发板对应的 linux 系统](#编译-nxp-官方开发板对应的-linux-系统)
    - [设置开发板、主机和ubuntu网络互连](#设置开发板主机和ubuntu网络互连)
    - [在 U-Boot 中添加正点原子的开发板](#在-u-boot-中添加正点原子的开发板)
  - [CPU 主频和网络驱动修改](#cpu-主频和网络驱动修改)
    - [修改 bootcmd 和 bootargs](#修改-bootcmd-和-bootargs)
    - [CPU 主频修改](#cpu-主频修改)
      - [设置超频，添加频率](#设置超频添加频率)
    - [使能 8 线 EMMC 驱动](#使能-8-线-emmc-驱动)
    - [修改网络驱动](#修改网络驱动)
    - [网络驱动测试](#网络驱动测试)
    - [保存修改后的图形化配置](#保存修改后的图形化配置)
  - [构建根文件系统](#构建根文件系统)
    - [使用 busybox](#使用-busybox)
      - [NFS 服务开启](#nfs-服务开启)
      - [拷贝解压 busybox](#拷贝解压-busybox)
      - [编译 busybox](#编译-busybox)
    - [向根文件系统添加 lib 库](#向根文件系统添加-lib-库)
    - [完善根文件系统](#完善根文件系统)
    - [软件运行测试](#软件运行测试)
    - [中文测试](#中文测试)
    - [开发板外网连接](#开发板外网连接)
- [第四期 驱动开发](#第四期-驱动开发)
  - [配置 vscode 开发环境](#配置-vscode-开发环境)
  - [字符设备开发基础实验](#字符设备开发基础实验)
  - [linux LED 灯驱动实验](#linux-led-灯驱动实验)
  - [设备树](#设备树)
    - [自定义节点](#自定义节点)
    - [特殊节点](#特殊节点)

------

# 裸机程序

## 开发环境的搭建

### 安装 NFS

```sh
sudo apt-get install nfs-kernel-server rpcbind
```

创建一个 zd-linux 文件夹啊，正点原子所有的东西都放在这个目录下，然后在这个文件夹下创建一个 nfs 文件夹给 nfs 服务器使用。

```
/home/book/kenspace/zd-linux
```

如何使用 NFS 服务器

```sh
sudo vim /etc/exports 

#添加
/home/book/kenspace/zd-linux/nfs q(rw,sync,no_root_squash) 

# 重启 NFS 服务器
sudo /etc/init.d/nfs-kernel-server restart
```

### CH340 驱动

如果想使用正点原子的串口就必须安装 CH340 驱动，在 `E:\学习资源\正点原子\【正点原子】阿尔法Linux开发板（A盘）-基础资料\03、软件\03、软件\CH340驱动(USB串口驱动)_XP_WIN7共用` 这个目录下。

在安装之前必须将开发板和电脑连接，电源打开，双击 SETUP.EXE，等待安装完成，打开设备管理器查看端口，最后使用 SecureCRT 连接对应的端口。

拨码开关：EMMC 模式：1 0 1 0 0 1 1 0

连接上之后按下复位键，看到 secureCRT 有数据输出，说明已经正常工作了。

### 安装交叉编译器

在 X86 架构的 PC 上运行，可以编译 ARM 架构代码的 GCC 编译器，这个编译器就叫做交叉编译器。

编译器可以再 `E:\学习资源\正点原子\【正点原子】阿尔法Linux开发板（A盘）-基础资料\05、开发工具\05、开发工具\01、交叉编译器` 下找到

将编译器上传到 ubuntu ，然后拷贝到 `/usr/local/arm` 目录中并对其进行解压。

```sh
sudo tar -xf gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz 
```

然后配置环境变量

```sh
sudo vim /etc/profile

export PATH=$PATH:/usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin
```

## 汇编语言编写 LED 驱动

- 创建逻辑驱动目录

```sh
mkdir MIX6ULL
/home/book/kenspace/zd-linux/IMX6ULL/board_drivers
/home/book/kenspace/zd-linux/IMX6ULL/board_drivers/1_leds
vim led.s
```


**I.MX6ULL IO初始化：**

- 使能时钟，CCGR0-CCGR6 这 7 个寄存器控制着 6ULL 所有外设时钟的使能，为了简单，在程序中将 CCGR0~CCGR6 这7个寄存器全部设置为 0XFFFFFFFF， 相当于使能所有外设时钟。

首先我们需要在 IMX6ULL 参考手册中查找到 CCGR0-CCGR6 的地址，找到 18 章 CCM 的 CCM_CCGR0 ，找到 CCM_CCGR0 ~ CCM_CCGR6 , 地址是：`Address: 20C_4000h base + 68h offset = 20C_4068h`

- IO复用，将寄存器 IOMUXC_SW_MUX_CTL_PAD_GPIO1_IO03 的 bit3~0 设置为 0101=5 ，这样 GPIO1_IO03 就复用为 GPIO

找到 30 章中 IOMUXC_SW_MUX_CTL_PAD_GPIO1_IO03 的地址，并将它设置为 5

- 寄存器 IOMUXC_SW_PAD_CTL_PAD_GPIO1_IO03 是设置 GPIO1_IO03 的电气属性。包括压摆率、速度、驱动能力、开漏、上下拉等。

找到 IOMUXC_SW_PAD_CTL_PAD_GPIO1_IO03 的地址是 0x020E02F4

- 配置 GPIO 功能，设置输入输出。设置 GPIO1_DR 寄存器 bit3 为 1，也就是设置为输出模式。设置 GPIO1_DR 寄存器的 bit3，为1表示输出高电平，为 0 表示输出低电平。

通过查看手册查到 GPIO1_GDIR 的地址是 0x0209C004

```x86asm
.global _start

_start:
    @ 初始化。使能所有外设时钟
    @ LDR 主要用于从存储加载数据到寄存器 Rx 中，LDR 也可以将一个立即数加载到寄存器 Rx 中
	ldr r0, =0x020c4068  @ CCGR0
    ldr r1, =0XFFFFFFFF  @ 要向 CCGR0 写入的数据，先初始化 0XFFFFFFFF 
	str r1, [r0]        @ 将0xFFFFFFFF写入到CCGR0中

    @ CCGR1
    ldr r0, =0x020C406C  @ CCGR1
    str r1, [r0]

    @ CCGR2
    ldr r0, =0x020C4070
    str r1, [r0]

    @ CCGR3
    ldr r0, =0x020C4074
    str r1, [r0]

    @ CCGR4
    ldr r0, =0x020C4078
    str r1, [r0]

    @ CCGR5
    ldr r0, =0x020C407C
    str r1, [r0]

    @ CCGR6
    ldr r0, =0x020C4080
    str r1, [r0]


    @ IO复用，将寄存器 IOMUXC_SW_MUX_CTL_PAD_GPIO1_IO03 的 bit3~0 设置为 0101=5 ，
    @ 这样 GPIO1_IO03 就复用为 GPIO
    /*
    配置 GPIO1_IO03 PIN 的复用为 GPIO ，也就是设置
    IOMUXC_SW_MUX_CTL_PAD_GPIO1_IO03 = 5
    IOMUXC_SW_MUX_CTL_PAD_GPIO1_IO03 寄存器的地址是  0x020E0068
     */

    ldr r0, =0x020e0068
    ldr r1, =0x5
	str r1, [r0]

    @ 寄存器IOMUXC_SW_PAD_CTL_PAD_GPIO1_IO03是设置 GPIO1_IO03的电气属性。
    @ 包括压摆率、速度、驱动能力、开漏、上下拉等。
    /* 
    *  bit0:    0 低速率
     * bit5:3： 110 R0/6驱动能力
     * bit7:6： 10 100MHz速度
     * bit11：  0 关闭开路输出
     * bit12：  1 使能pull/kepper
     * bit13：  0 kepper
     * bit15:14：00 100K下拉
     * bit16： 0 关闭hys
    */
    @ 换成 16 进制是 10B0
    ldr r0, =0x020e02f4
    ldr r1, =0x010B0
    str r1, [r0]

    /* 设置GPIO 
     * 设置GPIO1_GDIR寄存器，设置GPIO1_GPIO03为输出
     * GPIO1_GDIR寄存器地址为 0x0209c004,设置GPIO1_GDIR寄存器bit3为1,
     * 也就是设置GPIO1_IO03为输出。
     */
     ldr r0, =0x0209c004
     ldr r1, =0x08
     str r1, [r0]

     /* 打开LED，也就是设置GPIO1_IO03为0 也就是低电平
      * GPIO1_DR 寄存器地址为 0x0209c000
      */
    ldr r0, =0x0209c000
    ldr r1, =0
    str r1, [r0]

    @ 不断的循环
loop:
    b loop  @ 跳转到 loop
    @ 这里需要一个回车换行，否则会出现警告
```

### 编译驱动

编译到 SD 卡

- 编译

```sh
arm-linux-gnueabihf-gcc  -g -c led.s -o led.o   # -g 是产生调试信息， -c 是指定源文件
```

- 链接

> STM32 的存储起始地址和运行起始地址都是 0X08000000    
> 对于 6ULL 来说，链接起始地址应该指向 RAM 地址。RAM 分为内部 RAM 和外部 RAM，也就是 DDR     
> 本教程所有裸机例程的链接地址都在 DDR 中，链接起始地址为 0X87800000

```sh
arm-linux-gnueabihf-ld -Ttext 0X87800000 led.o -o led.elf
```

- 将 elf 文件转成 bin 文件

```sh
arm-linux-gnueabihf-objcopy -O binary -S -g led.elf led.bin
```

- 查看 SD 卡名称

```sh
$ ll /dev/sd*
brw-rw---- 1 root disk 8,  0 Mar 14 23:30 /dev/sda
brw-rw---- 1 root disk 8,  1 Mar 14 23:30 /dev/sda1
brw-rw---- 1 root disk 8,  2 Mar 14 23:30 /dev/sda2
brw-rw---- 1 root disk 8,  3 Mar 14 23:30 /dev/sda3
brw-rw---- 1 root disk 8,  4 Mar 14 23:30 /dev/sda4
brw-rw---- 1 root disk 8, 16 Mar 15 21:33 /dev/sdb
brw-rw---- 1 root disk 8, 17 Mar 15 21:33 /dev/sdb1
```

- 开始烧写

在 ubuntu 下烧写，所以需要把 SD 卡挂到 ubuntu 中去。烧写就是将 bin 文件写到绝对地址上。用 Imxdownlaod 烧写。

Imxdownlaod 会向 `led.bin` 添加一个头部，生成新的 `load.imx` 文件，这个 load.imx 文件就是最终烧写到SD卡里面去的。

```sh
 ./imxdownload led.bin /dev/sdb
 imxdownload led.bin /dev/sdb1  # 或者
```


### 将板子连接到 PC

使用 USB 线连接，secureCRE 连接时，注意 Band rate 选择 115200 。


### makefile 的编写

```
led.bin : led.s
	# 编译成目标文件
	arm-linux-gnueabihf-gcc -g -c led.s -o led.o
	# 链接
	arm-linux-gnueabihf-ld -Ttext 0x87800000 led.o -o led.elf
	# 转成二进制 bin 文件
	arm-linux-gnueabihf-objcopy -O binary -S -g led.elf led.bin
	# 反汇编
	arm-linux-gnueabihf-objdump -D led.elf > led.dis

clean:
	rm -rf *.o led.bin led.elf led.dis
```

烧写进 SD 卡

```sh
 imxdownload led.bin /dev/sdb1  # 或者
```

-----

##  C 语言编写 LED 驱动


### 设置处理器模式

设置 6ULL 处于 SVC 模式 下。设置 CPSR 寄存器的 bit4-0，也就是 M[4:0] 为 10011=0X13。读写状态寄存器需要用到 MRS 和 MSR 指令。MRS 将 CPSR 寄存器数据读出到通用寄存器里面，MSR 指令将通用寄存器的值写入到 CPSR 寄存器里面去。

### 设置 SP 指针

SP 指针可以指向内部 RAM，也可以指向 DDR，我们这里将其指向 DDR。

使用 b 指令，跳转到 C 语言函数，比如 main 函数。

### 编译烧录

需要将 imx6u.lds 文件拷贝当代码路径下

make

imxdownload ledc.bin /dev/sdb1

## stm32 模式编写LED驱动

> 先放一放 看不懂

----
----


# 第三期 系统移植

## 烧写实验

### 使用 OTG 烧写

使用 mfgtool 先开发板烧写系统，先将拨码快关打到 USB 模式，切记使用 OTG 烧写的时候需要将 SD 卡拔出来，等连接到开发板后可以插进去。

双击 Mfgtool2-eMMC-ddr512-eMMC.vbs ，出现 【符合 HID 标准的供应商定义设备】 就表示开发板和电脑连接成功。

将拨码开关拨到 EMMC，开始启动。

### Ubuntu 脚本烧写

向 SD 卡烧写一个系统，然后使用 SD 卡系统。

将 `D:\kendallStudy\正点原子第三期\mfgtool\Profiles\Linux\OS Firmware\files` 整个 files 整个文件夹拷贝到 ubuntu 中。

```sh
chmod +x imx6mksdboot.sh imx6mkemmcboot.sh
```

将 SD 卡接到 Ubuntu ，查看 `sudo fdisk -l`

```sh
 sudo ./imx6mksdboot.sh -device /dev/sdb -flash emmc -ddrsize 512
```

点击回车 --> 等待烧写完成即可，这时候查看 Ubuntu 中的文件夹可以看到多了个 rootfs 文件夹。往 EMMC 中烧写，所以需要将其存到 rootfs 中，存到 rootfs 的 home/root 文件夹下。直接将 ubuntu 下的 files 文件夹复制到 rootfs 的 home/root 文件夹下。然后执行 sync 同步操作。


拔掉 SD 卡，并使用 SD 卡系统。

- 从 SD 卡系统系统后，需要烧录到 EMMC 中去

```sh
root@ATK-IMX6U:~/files# ./imx6mkemmcboot.sh --help

fdisk -l # 找到 EMMC
# Disk /dev/mmcblk1: 7.3 GiB, 7818182656 bytes, 15269888 sectors

root@ATK-IMX6U:~/files# ./imx6mkemmcboot.sh -device /dev/mmcblk1 -ddrsize 512
```

> 如果想要还原 SD 卡可以使用 SDFormatter(内存卡修复工具).exe 工具

## Uboot 编译和烧写

uboot 就是一个 bootloader，作用是用于启动 kernel，最主要的工作是初始化 DDR，一般 Linux 镜像 zImage(uImage)+设备树(.dtb)存放在 SD、EMMC、NAND、SPI FLASH 等等外置存储区域。

```sh
# 解压
book@kendall:uboot$ tar jxf uboot-imx-2016.03-2.1.0-gee88051-v1.6.tar.bz2 
```

编译 uboot 的时候需要进行配置，

```sh
#!/bin/bash

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- mx6ull_14x14_ddr512_emmc_defconfig

make V=1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4
```

> 也可以将上面编写层脚本：chmod +x mx6ull_alientek_emmc.sh ，**如果配置过uboot，那么一定要注意shell脚本会清除整个工程，那么配置的文件也会被删除，配置项也会被删除掉。**

> 可以修改 Makefile

```mk
 249 ARCH ?= arm
 250 CROSS_COMPILE ?= arm-linux-gnueabihf- 
```

之后可以使用 make -j4 直接编译。

```sh
 make distclean
 make mx6ull_14x14_ddr512_emmc_defconfig
 make -j4
```

编译完成以后就会生成一个 u-boot.bin。必须向 u-boot.bin 添加头部信息。Uboot编译最后会通过 /tools/mkimage 软件添加头部信息，生成 u-boot.imx。

将 u-boot.imx 拷贝到 `D:\kendallStudy\正点原子第三期\mfgtool\Profiles\Linux\OS Firmware\firmware`, 并将名字修改成 `u-boot-imx6ull-14x14-emmc.imx`.

在复制一份到 `D:\kendallStudy\正点原子第三期\mfgtool\Profiles\Linux\OS Firmware\files\boot` 文件夹下，命名为：`u-boot-imx6ull-14x14-ddr512-emmc`

连接 OTB 线连接上去，拨码开关：0 1 .....

双击 ：Mfgtool2-eMMC-ddr512-eMMC.vbs

烧写完成后将拨码开关设置成 EMMC 启动。然后复位启动。

在启动倒计时时【按住回车】进入 uboot 命令行模式。

## 启动 Uboot 分析

```sh
 make distclean
 make mx6ull_14x14_ddr512_emmc_defconfig
 make -j4
```

烧写进 SD 卡

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/uboot
imxdownload u-boot.bin /dev/sdb
```

使用 SD 卡启动开发板，查看 log

### uboot 源码目录

先编译 uboot，使用上面的方式，

- api: 与硬件无关的 API 函数
- arch：与架构体系有关的代码
- board：不同开发板的定制代码
- cmd：命令相关代码
- common：通用代码
- configs：配置文件
- disk：磁盘分区相关代码
- doc：文档
- drivers：驱动代码
- dts：设备树
- examples：示例代码
- fs：文件系统
- include：头文件
- lib：库文件
- License：许可证相关代码
- net：网络相关代码
- psot：上电自检程序
- scripts：脚本文件
- test：测试代码
- tools：工具文件夹


Makefile 调试

```mk
mytest:
    echo srctree=$(srctree)
```

### uboot 启动流程

uboot 根目录下生成 u-boot.lds文件是 uboot 启动的起始地址。编译 u-boot 后才会在根目录下出现 u-boot.lds.

里面有个 __image_copy_start ，它的地址在 u-boot.map 中可以找到

- __image_copy_start >> 0x0000000087800000
  - u-boot.map 是 uboot 的映射文件，可以从此文件看到某个文件或者函数链接到了哪个地址
- vectors >>  0x0000000087800000  存放中断向量表
-  arch/arm/cpu/armv7/start.o(.text*) --> start.c  

```s
 .text :
 {
  *(.__image_copy_start)
  *(.vectors)
  arch/arm/cpu/armv7/start.o (.text*)
  *(.text*)
 }
```

- image_copy_end >> 0x000000008784e9ec
  - 不同的编译地址可能不一样

- rel 段
- rel_dyn_start >> 0x000000008784e9ec
- __rel_dyn_end >> 0x000000008785707c


vectors.S 中

reset 函数在 arch/arm/cpu/armv7/start.S 里面


---



## linux 内核移植

> E:\学习资源\正点原子\【正点原子】阿尔法Linux开发板（A盘）-基础资料\01、例程源码\01、例程源码\04、NXP官方原版Uboot和Linux\

拷贝 linux-imx-rel_imx_4.1.15_2.1.0_ga.tar 到  `/home/book/kenspace/zd-linux/IMX6ULL/linux`。

```sh
tar xjf linux-imx-rel_imx_4.1.15_2.1.0_ga.tar.bz2 
```

### 编译 NXP 官方开发板对应的 linux 系统

创建 imx6ull_14x14_evk.sh 文件

```sh
#!/bin/bash

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean

# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/configs/imx_v7_mfg_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_v7_mfg_defconfig

make V=1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

make V=1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4
```

```sh
chmod  +x imx6ull_14x14_evk.sh

./imx6ull_14x14_evk.sh
```

编译完成生成的设备树文件在

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts

ls imx6ull*.dts

# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot
ls zIamge
```

最终编译出 zImage 和生成 imx6ull-14x14-evk-emmc.dtb 

需要将 imx6ull-14x14-evk-emmc.dtb 和 zImage 这两个文件拷贝到 tftpboot 目录下，然后在 uboot 通过网络 tftp 服务启动。

```sh
cp IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/zImage ./tftpboot -f

cp IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts/imx6ull-14x14-evk-emmc.dtb ./tftpboot/ -f
```

**使用 SD 卡启动开发板，进入 uboot 命令行模式**

通过 => tftp 80800000 zImage 这个命令下载 ZImage 

可以尝试 uboot 上 ping 一下 UBunut 的 ip 地址

```sh
=> ping 192.168.91.130
# ERROR: `ipaddr' not set
```

- 原因：没有网络配置
- 解决：设置网络信息

### 设置开发板、主机和ubuntu网络互连

参考：https://blog.csdn.net/lylg_ban/article/details/121657952

参考：`E:\学习资源\正点原子\【正点原子】阿尔法Linux开发板（A盘）-基础资料\10、用户手册\10、用户手册\【正点原子】I.MX6U网络环境TFTP&NFS搭建手册V1.3.1.pdf`


设置 uboot ip

> 在 EMMC 模式执行 ifconfig 拷贝的：88:f8:d2:4b:bf:f2

```sh
setenv ipaddr 192.168.10.50
setenv ethaddr 88:f8:d2:4b:bf:f2
setenv gatewayip 192.168.10.1
setenv netmask 255.255.255.0
setenv serverip 192.168.10.100
saveenv

Saving Environment to MMC...
Writing to MMC(0)... done
=> ping 192.168.10.100
FEC1 Waiting for PHY auto negotiation to complete.... done
Using FEC1 device
host 192.168.10.100 is alive
```

继续参考上面文档配置 TFTP

```
server tftp
    {
        socket_type = dgram
        wait = yes
        disable = no
        user = root
        protocol = udp
        server = /usr/sbin/in.tftpd
        server_args = -s /home/book/kenspace/zd-linux/tftpboot -c
        #log_on_success += PID HOST DURATION
        #log_on_failure += HOST
        per_source = 11
        cps =100 2
        flags =IPv4
    }
```

在 uboot 执行 tftp 80800000 zImag

```
=> tftp 80800000 zImage
Using FEC1 device
TFTP from server 192.168.10.100; our IP address is 192.168.10.50
Filename 'zImage'.
Load address: 0x80800000
Loading: #################################################################
         #################################################################
         #################################################################
         #################################################################
         #################################################################
         ########################################################


=> tftp 83000000 imx6ull-14x14-evk-emmc.dtb
Using FEC1 device
TFTP from server 192.168.10.100; our IP address is 192.168.10.50
Filename 'imx6ull-14x14-evk-emmc.dtb'.
Load address: 0x83000000
Loading: ###
         1.1 MiB/s
done
Bytes transferred = 36093 (8cfd hex)


# 启动
=> bootz 80800000 - 83000000

...
hub 1-1:1.0: USB hub found
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
```

出现上面信息是因为没有根文件系统导致的。

综上所述，NPX 官网的 ZImage 和 dtb 可以在正点原子开发板启动。



### 在 U-Boot 中添加正点原子的开发板

- 复制 `arch/arm/configs/imx_v7_mfg_defconfig` 文件为`imx_alientek_emmc_defconfig`。
- 复制`arch/arm/boot/dts/imx6ull-14x14-evk.dts`文件为`imx6ull-alientek-emmc.dts`

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/configs
cp imx_v7_mfg_defconfig imx_alientek_emmc_defconfig

# 设备树
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts
cp imx6ull-14x14-evk.dts imx6ull-alientek-emmc.dts
```

修改 dts 的 Makefile

```mk
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts
418     imx6ull-alientek-emmc.dtb \
```

编写脚本

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga
book@kendall:linux-imx-rel_imx_4.1.15_2.1.0_ga$ cp imx6ull_14x14_evk.sh imx6ull-alientek-emmc.sh
```

vim imx6ull-alientek-emmc.sh 

```sh
#!/bin/bash                                                                                                                                   
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean

# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/configs/imx_alientek_emmc_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_alientek_emmc_defconfig

make  ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

make  ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4 
```


开始编译

./imx6ull-alientek-emmc.sh

- 为了快速编译，修改顶层 Makefile

```mk
 257 ARCH ?= arm  
 258 CROSS_COMPILE ?= arm-linux-gnueabihf-
```

- 之后执行 make 编译就可以了


```sh
make distclean
make CROSS_COMPILE=imx6ull_alientek_emmc_defconfig
make -j4
```

编译出来的 zImage `arch/arm/boot/Image`

编译出来的 imx6ull-alientek-emmc.dtb  `arch/arm/boot/dts`

拷贝

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts
cp imx6ull-alientek-emmc.dtb ~/kenspace/zd-linux/tftpboot/

# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot
cp zImage ~/kenspace/zd-linux/tftpboot/
```


- 拷贝完成后复位开发板



```sh
# 下载镜像
tftp 80800000 zImage

# 下载设备树
tftp 83000000 imx6ull-alientek-emmc.dtb

bootz 80800000 - 83000000
```


## CPU 主频和网络驱动修改

- 设置通过网络启动的 bootcmd ，这样直接复位，不需要，如果【不回车】就会自动进入 kernel 了。

### 修改 bootcmd 和 bootargs

- 修改 bootcmd

```
setenv bootcmd 'tftp 80800000 zImage;tftp 83000000 imx6ull-alientek-emmc.dtb;bootz 80800000 - 83000000;'

saveenv
```

- 设置加载默认的 根文件系统， 设置 bootargs


```sh
# onsole=ttymxc0 是 imx6uLL 开发板串口 1 的设备，也就是控制台使用串口 1
# root=根文件系统位置，p2 表示 EMMC 的第二个分区
setenv bootargs 'console=ttymxc0,115200 root=/dev/mmcblk1p2 rootwait rw'
saveenv
```

> 修改完成之后再启动 uboot 的时候会自动去执行这些命令去加载 zImage 和 dtb

- 修改解决驱动问题

```sh
book@kendall:tftpboot$ vim ../IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts/imx6ull-alientek-emmc.dts

# 找到描述 EMMC 板子设备信息的节点
&usdhc2 {                                                                                                                                     
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_usdhc2>;
    non-removable;
    status = "okay";
};

# 找到 book@kendall:tftpboot$ vim ../IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts/imx6ull-14x14-evk-emmc.dts
&usdhc2 {
    pinctrl-names = "default", "state_100mhz", "state_200mhz";
    pinctrl-0 = <&pinctrl_usdhc2_8bit>;
    pinctrl-1 = <&pinctrl_usdhc2_8bit_100mhz>;
    pinctrl-2 = <&pinctrl_usdhc2_8bit_200mhz>;
    bus-width = <8>;
    non-removable;
    status = "okay";
};
```

- 将 imx6ull-14x14-evk-emmc.dts 的 &usdhc2 信息复制到 imx6ull-alientek-emmc.dts 的 &usdhc2 下（覆盖掉原来的），如下所示：

```
&usdhc2 {
    pinctrl-names = "default", "state_100mhz", "state_200mhz";
    pinctrl-0 = <&pinctrl_usdhc2_8bit>;
    pinctrl-1 = <&pinctrl_usdhc2_8bit_100mhz>;
    pinctrl-2 = <&pinctrl_usdhc2_8bit_200mhz>;
    bus-width = <8>;
    non-removable;
    status = "okay";
};
```

- 直接编译被修改过的设备树

make dtbs

> 注意第一次执行的话需要先需要通过 ./imx6ull-alientek-emmc.sh 来进行编译。

- 复位开发板，启动 kernel

### CPU 主频修改

- 查看 CPU 信息 

root@ATK-IMX6U:/# cat /proc/cpuinfo 
  
- 查看 CPU 的工作频率

```
cd /sys/bus/cpu/devices/cpu0/cpufreq/
cat cpuinfo_cur_freq 
792000
```

- 找到配置文件

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm
$ vim imx_alientek_emmc_defconfig

 42 CONFIG_CPU_FREQ=y                                                                                                                         
 43 CONFIG_CPU_FREQ_GOV_POWERSAVE=y
 44 CONFIG_CPU_FREQ_GOV_USERSPACE=y
 45 CONFIG_CPU_FREQ_GOV_ONDEMAND=y
 46 CONFIG_CPU_FREQ_GOV_CONSERVATIVE=y
```

- 可以看到所有的 CPU 都使能了，我们可以通过图形化界面进行配置

```sh
# /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga
$ make menuconfig

CPU Power Management  ---> 
  ==>  CPU Frequency scaling
    ==>  Default CPUFreq governor (ondemand)  ---> 
      ==>  (X) ondemand 
```

- YES 保存退出，更改成根据负载动态调频

make -j4

- 编译完成之后，需要将 zImage 拷贝到 tftpboot 

cp arch/arm/boot/zImage ../../../tftpboot/

- 复位启动 kernel

#### 设置超频，添加频率

- 重新查看 CPU 频率 

root@ATK-IMX6U:/# cat /proc/cpuinfo 
  
- 查看 CPU 的工作频率

```
root@ATK-IMX6U:/sys/devices/system/cpu/cpu0/cpufreq# cat cpuinfo_cur_freq 
528000
```

- 可以看到主频从原来的 792000 变成 396000 了。

- 查看当前支持的频率

可以看出当前的 CPU 支持的 198MHz、196MHz、528MHz 和 518MHz 四种频率切换，其中调频策略为 ondemand，也就是定期检测负载，然后根据负载情况调节 CPU 频率。因为我们当前开发板还没做什么工作，因此 CPU 频率降低为 198MHz 以省电。但是如果开发板做一些高负载的工作，比如播放视频等，那么 CPU 频率就会提升扇区。查看 stats 目录下的 time_in_state 可以看到 CPU 在各个频率下的工作时间。

```sh
root@ATK-IMX6U:/sys/devices/system/cpu/cpu0/cpufreq# cat stats/time_in_state 
198000 66262
396000 251232
528000 800
792000 2313
```

从上面的打印结果可以看出，CPU 在 198MHz、396MHz、528MHz 和 792MHz 都工作过，其
中 198MHz 的工作时间最长！



### 使能 8 线 EMMC 驱动

Linux 内核驱动里面 EMMC 默认是 4 线模式的，4 线模式肯定没有 8 线模式的速度快，所以本节我们将 EMMC 的驱动修改为 8 线模式

> 通过修改设备树实现，imx6ull-alientek-emmc.dts 的 usdhc2 节点

> **开发板中已经做好了**

修改完成以后保存一下 imx6ull-alientek-emmc.dts，然后使用命令“ make dtbs ”重新编译一下设备树，编译完成以后使用新的设备树重启 Linux 系统即可。

### 修改网络驱动

我们通过网络挂载进行驱动 kernel，直接把镜像文件和设备树文件放在 ubuntu 里面，然后通过网络挂载到开发板。

- 修改 LAN8720 的复位以及网络时钟引脚驱动【不改】

ENET1 复位引脚 ENET1_RST 连接在 I.M6ULL 的 SNVS_TAMPER7 这个引脚上。ENET2 的复位引脚 ENET2_RST 连接在 I.MX6ULL 的 SNVS_TAMPER8 上。打开设备树文件 imx6ull-alientek-emmc.dts ，并找到

```c
		pinctrl_spi4: spi4grp {
                        fsl,pins = <
                                MX6ULL_PAD_BOOT_MODE0__GPIO5_IO10        0x70a1
                                MX6ULL_PAD_BOOT_MODE1__GPIO5_IO11        0x70a1
							                	/* comment out following two lines */
                                /* MX6ULL_PAD_SNVS_TAMPER7__GPIO5_IO07      0x70a1 */
                                /* MX6ULL_PAD_SNVS_TAMPER8__GPIO5_IO08      0x80000000 */
                        >;
                };
```

- 继续找到 spi4 【不改】

 GPIO5_IO07 和 GPIO5_IO08 分别作为 ENET1 和 ENET2 的复位引脚，而不是 SPI4 的什么功能引脚

```c
    spi4 {
        compatible = "spi-gpio";
        pinctrl-names = "default";
        pinctrl-0 = <&pinctrl_spi4>;
        /* pinctrl-assert-gpios = <&gpio5 8 GPIO_ACTIVE_LOW>; */
        status = "okay";
        gpio-sck = <&gpio5 11 0>; 
        gpio-mosi = <&gpio5 10 0>;
        /* cs-gpios = <&gpio5 7 0>; */
        num-chipselects = <1>;
        #address-cells = <1>;                                                                                                                 
        #size-cells = <0>;
```

- 添加网络引脚信息，修改 iomuxc_snvs

```c
&iomuxc_snvs {
	pinctrl-names = "default_snvs";
        pinctrl-0 = <&pinctrl_hog_2>;
        imx6ul-evk {
			pinctrl_hog_2: hoggrp-2 {
							fsl,pins = <
									MX6ULL_PAD_SNVS_TAMPER0__GPIO5_IO00      0x80000000
							>;
					};

			pinctrl_dvfs: dvfsgrp {
							fsl,pins = <
									MX6ULL_PAD_SNVS_TAMPER3__GPIO5_IO03      0x79
							>;
					};
			
			pinctrl_lcdif_reset: lcdifresetgrp {
							fsl,pins = <
									/* used for lcd reset */
									MX6ULL_PAD_SNVS_TAMPER9__GPIO5_IO09  0x49
							>;
					};

			pinctrl_spi4: spi4grp {
							fsl,pins = <
									MX6ULL_PAD_BOOT_MODE0__GPIO5_IO10        0x70a1
									MX6ULL_PAD_BOOT_MODE1__GPIO5_IO11        0x70a1
									MX6ULL_PAD_SNVS_TAMPER7__GPIO5_IO07      0x70a1
									MX6ULL_PAD_SNVS_TAMPER8__GPIO5_IO08      0x80000000
							>;
					};

			pinctrl_fec1_reset: fec1_resetgrp {
				fsl,pins = <
					MX6ULL_PAD_SNVS_TAMPER7__GPIO5_IO07	0x79
				>;
			};

			pinctrl_fec2_reset: fec2_resetgrp {
				fsl,pins = <
					MX6ULL_PAD_SNVS_TAMPER8__GPIO5_IO08	0x79
				>;
			};

			pinctrl_sai2_hp_det_b: sai2_hp_det_grp {
					fsl,pins = <
							MX6ULL_PAD_SNVS_TAMPER4__GPIO5_IO04   0x17059
					>;
			};

			ts_reset_pin: ts_reset_pin_mux {
				fsl,pins = <
					MX6ULL_PAD_SNVS_TAMPER9__GPIO5_IO09	0x49
				>;
			};

			pinctrl_beep: beep {
				fsl,pins = <
					MX6ULL_PAD_SNVS_TAMPER1__GPIO5_IO01	0x17059
				>;
			};
        };
};
```

- 接着修改 pinctrl_enet1: enet1grp 【可以不改】

分别为 ENET1 和 ENET2 的网络时钟引脚配置信息，将这两个引脚的电气属性值改为 0x4001b009，原来默认值为 0x4001b031。

```c
		pinctrl_enet1: enet1grp {
			fsl,pins = <
				MX6UL_PAD_ENET1_RX_EN__ENET1_RX_EN	0x1b0b0
				MX6UL_PAD_ENET1_RX_ER__ENET1_RX_ER	0x1b0b0
				MX6UL_PAD_ENET1_RX_DATA0__ENET1_RDATA00	0x1b0b0
				MX6UL_PAD_ENET1_RX_DATA1__ENET1_RDATA01	0x1b0b0
				MX6UL_PAD_ENET1_TX_EN__ENET1_TX_EN	0x1b0b0
				MX6UL_PAD_ENET1_TX_DATA0__ENET1_TDATA00	0x1b0b0
				MX6UL_PAD_ENET1_TX_DATA1__ENET1_TDATA01	0x1b0b0
				/* MX6UL_PAD_ENET1_TX_CLK__ENET1_REF_CLK1	0x4001b031 */
				MX6UL_PAD_ENET1_TX_CLK__ENET1_REF_CLK1 0x4001b009
			>;
		};

		pinctrl_enet2: enet2grp {
			fsl,pins = <
				MX6UL_PAD_GPIO1_IO07__ENET2_MDC		0x1b0b0
				MX6UL_PAD_GPIO1_IO06__ENET2_MDIO	0x1b0b0
				MX6UL_PAD_ENET2_RX_EN__ENET2_RX_EN	0x1b0b0
				MX6UL_PAD_ENET2_RX_ER__ENET2_RX_ER	0x1b0b0
				MX6UL_PAD_ENET2_RX_DATA0__ENET2_RDATA00	0x1b0b0
				MX6UL_PAD_ENET2_RX_DATA1__ENET2_RDATA01	0x1b0b0
				MX6UL_PAD_ENET2_TX_EN__ENET2_TX_EN	0x1b0b0
				MX6UL_PAD_ENET2_TX_DATA0__ENET2_TDATA00	0x1b0b0
				MX6UL_PAD_ENET2_TX_DATA1__ENET2_TDATA01	0x1b0b0
				/* MX6UL_PAD_ENET2_TX_CLK__ENET2_REF_CLK2	0x4001b031 */
				MX6UL_PAD_ENET2_TX_CLK__ENET2_REF_CLK2	0x4001b009
			>;
		};
```

编译 make dtbs

- 修改 fec1 和 fec2 节点的 pinctrl-0 属性

在 imx6ull-alientek-emmc.dts 文件中找到名为“fec1”和“fec2”的这两个节点，修改其中的 “pinctrl-0” 属性值。

找到 &fec1

```c
&fec1 {
	pinctrl-names = "default";
	pinctrl-0 = <&pinctrl_enet1
		     &pinctrl_fec1_reset>;
	phy-mode = "rmii";
	phy-handle = <&ethphy0>;
	phy-reset-gpios = <&gpio5 7 GPIO_ACTIVE_LOW>;
	phy-reset-duration = <200>;
	status = "okay";
};
&fec2 {
	pinctrl-names = "default";
	pinctrl-0 = <&pinctrl_enet2
		     &pinctrl_fec2_reset>;
	phy-mode = "rmii";
	phy-handle = <&ethphy1>;
	phy-reset-gpios = <&gpio5 8 GPIO_ACTIVE_LOW>;
	phy-reset-duration = <200>;
	status = "okay";
```

ENET1 的 LAN8720A 地址为 0x0，ENET2 的 LAN8720A 地址为 0x1。在 imx6ull-alientek-emmc.dts 中找到如下代码


- 修改 LAN8720A 的 PHY 地址

```c
	mdio {
		#address-cells = <1>;
		#size-cells = <0>;

		ethphy0: ethernet-phy@2 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <0>;
		};

		ethphy1: ethernet-phy@1 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <1>;
		};
	};
```

- 修改 fec_main.c 文件

要 在 I.MX6ULL 上 使 用 LAN8720A ， 需 要 修 改 一 下 Linux 内 核 源 码 ， 打开 `drivers/net/ethernet/freescale/fec_main.c`，找到函数 fec_probe ，在 fec_probe 中加入如下代码，设置 `MX6UL_PAD_ENET1_TX_CLK` 和 `MX6UL_PAD_ENET2_TX_CLK` 这两个 IO 的复用寄存器的 SION 位为 1。


```c
	/* add code  start*/
	void __iomem *IMX6U_ENET1_TX_CLK;
	void __iomem *IMX6U_ENET2_TX_CLK;

	IMX6U_ENET1_TX_CLK = ioremap(0X020E00DC, 4);
	writel(0X14, IMX6U_ENET1_TX_CLK);

	IMX6U_ENET2_TX_CLK = ioremap(0X020E00FC, 4);
	writel(0X14, IMX6U_ENET2_TX_CLK);
	/* add code  end*/
```

输入命令“ make menuconfig ”，打开图形化配置界面，选择使能 LAN8720A 的驱动

```
-> Device Drivers  --->  
  -> Network device support  --->  
    -> PHY Device support and infrastructure  --->
       -> <*>   Drivers for SMSC PHYs    
```

编译拷贝

```sh
make dtbs
cp arch/arm/boot/dts/imx6ull-alientek-emmc.dtb ~/kenspace/zd-linux/tftpboot/
```

- 修改 smsc.c 文件

到 LAN8720A 的驱动文件，LAN8720A 的驱动文件是 drivers/net/phy/smsc.c ，在此文件中有个叫做 smsc_phy_reset 的函数。

```c
// $ vim drivers/net/phy/smsc.c


static int smsc_phy_reset(struct phy_device *phydev)
{
	int err, phy_reset;
	int msec = 1;
	int rc;
	int timeout = 50000;
	struct device_node *np;

	np = NULL;

	if(phydev->addr == 0) /* FEC1  */ {
		np = of_find_node_by_path("/soc/aips-bus@02100000/ethernet@02188000");
		if(np == NULL) {
			return -EINVAL;
		}
	}

	if(phydev->addr == 1) /* FEC2  */ {
		np = of_find_node_by_path("/soc/aips-bus@02000000/ethernet@020b4000");
		if(np == NULL) {
			return -EINVAL;
		}
	}

	err = of_property_read_u32(np, "phy-reset-duration", &msec);
	/* A sane reset duration should not be longer than 1s */
	if (!err && msec > 1000)
		msec = 1;
	phy_reset = of_get_named_gpio(np, "phy-reset-gpios", 0);
	if (!gpio_is_valid(phy_reset))
		gpio_free(phy_reset);

	gpio_direction_output(phy_reset, 0);
	gpio_set_value(phy_reset, 0);
	msleep(msec);
	gpio_set_value(phy_reset, 1);

	rc = phy_read(phydev, MII_LAN83C185_SPECIAL_MODES);
	if (rc < 0)
		return rc;

	/* If the SMSC PHY is in power down mode, then set it
	 * in all capable mode before using it.
	 */
	if ((rc & MII_LAN83C185_MODE_MASK) == MII_LAN83C185_MODE_POWERDOWN) {

		/* set "all capable" mode and reset the phy */
		rc |= MII_LAN83C185_MODE_ALL;
		phy_write(phydev, MII_LAN83C185_SPECIAL_MODES, rc);
	}

	phy_write(phydev, MII_BMCR, BMCR_RESET);
	/* wait end of reset (max 500 ms) */
	do {
		udelay(10);
		if (timeout-- == 0)
			return -1;
		rc = phy_read(phydev, MII_BMCR);
	} while (rc & BMCR_RESET);

	return 0;
}
```

修改好设备树和 Linux 内核以后重新编译一下，得到新的 zImage 镜像文件和 imx6ull-alientek-emmc.dtb 设备树文件，最后使用新的文件启动 Linux 内核。启动以后使用“ifconfig”命令查看一下当前活动的网卡有哪些。

make -j4

拷贝

```sh
cp arch/arm/boot/zImage ~/kenspace/zd-linux/tftpboot/
cp arch/arm/boot/dts/imx6ull-alientek-emmc.dtb ~/kenspace/zd-linux/tftpboot/
```

**重新复位开发板**

### 网络驱动测试

通过 ifconfig -a 查看所有网卡

启动网卡

```sh
ifconfig eth0 up
ifconfig eth1 up
```

输入“ifconfig”命令来查看一下当前活动的网卡

可以看出，此时 eth0 和 eth1 两个网卡都已经打开，并且工作正常，但是这两个网卡都还没有 IP 地址，所以不能进行 ping 等操作。使用如下命令给两个网卡配置 IP 地址

```sh
ifconfig eth0 192.168.111.251
ifconfig eth1 192.168.111.252

ping 192.168.111.128
```

### 保存修改后的图形化配置

make menuconfig --> save -> 输入：arch/arm/configs/imx_alientek_emmc_defconfig  可能需要按住 ctrl+back 才能删除。

---------


## 构建根文件系统

### 使用 busybox

> 可以去 busybox 官网下载

构建根文件系统调试，通过 nfs 网络挂载，也就是根文件系统放在 Ubuntu 下，开发板启动后通过 nfs 服务使用 ubuntu 下的根文件系统。 

#### NFS 服务开启

sudo apt-get install nfs-kernel-server rpcbind

以后我们可以在开发板上通过网络文件系统来访问 nfs 文件夹，要先配置 nfs，使用如下命令打开 nfs 配置文件 `/etc/exports`：

打开 `vim /etc/exports` 以后在后面添加如下所示内容

```
/home/book/kenspace/zd-linux/nfs *(rw,sync,no_root_squash)
```

重启 NFS 服务，使用命令如下

sudo /etc/init.d/nfs-kernel-server restart

给 nfs 共享目录权限

chmod 777 nfs

------

#### 拷贝解压 busybox

```sh
tar -xjf busybox-1.29.0.tar.bz2

/home/book/kenspace/zd-linux/IMX6ULL/tools/busybox-1.29.0
```


#### 编译 busybox

- 修改 Makefile，添加交叉编译器

```mk
 191 CROSS_COMPILE ?= /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-                             
 192 ARCH ?= arm  
```

- busybox 中文字符支持

```c
// 修改 libbb/printable_string.c 

	/*	if (c >= 0x7f) */
	/*		break;  */

		//	if (c < ' ' || c >= 0x7f)
			if (c < ' ')

// libbb/unicode.c 
// *d++ = (c >= ' ' && c < 0x7f) ? c : '?';
  *d++ = (c >= ' ') ? c : '?';

//				if (c < ' ' || c >= 0x7f)
				if (c < ' ')    
```


- 配置 busybox

make defconfig

出现 .config 说明配置成功，但是这只是默认配置，可以通过图形界面进行配置

```sh
book@kendall:busybox-1.29.0$ make menuconfig

Location:
-> Settings
-> Build static binary (no shared libs)   (不要选中)

# 继续配置如下路径配置项

Location:
-> Settings
-> [*]   vi-style line editing commands

# 继续配置如下路径配置项

Location:
-> Linux Module Utilities
-> [ ] Simplified modutils 

# 继续配置如下路径配置项

Location:
-> Linux System Utilities
-> mdev (16 kb) //确保下面的全部选中，默认都是选中的

# 最后就是使能 busybox 的 unicode 编码以支持中文

Location:
-> Settings
->  [*] Support Unicode          # 选中
-> [*]   Check $LC_ALL, $LC_CTYPE and $LANG environment variables   # //选中
```


- 现在可以编译 busybox 了

COFIG_PREFIX 指定编译结果的存放目录

```sh
book@kendall:busybox-1.29.0$ make install CONFIG_PREFIX=/home/book/kenspace/zd-linux/nfs/rootfs

book@kendall:rootfs$ ls
bin  linuxrc  sbin  usr
```

编译完成以后会在 busybox 的所有工具和文件就会被安装到 rootfs 目录中，rootfs 目录下有 bin、sbin 和 usr 这三个目录，以及 linuxrc 这个文件。前面说过 Linux 内核 init 进程最后会查找用户空间的 init 程序，找到以后就会运行这个用户空间的 init 程序，从而切换到用户态。如果 bootargs 设置 `init=/linuxrc`，那么 linuxrc 就是可以作为用户空间的 init 程序，所以用户态空间的 init 程序是 busybox 来生成的。

### 向根文件系统添加 lib 库

- 向 rootfs 的“/lib”目录添加库文件

Linux 中的应用程序一般都是需要动态库的，当然你也可以编译成静态的，但是静态的可执行文件会很大。如果编译为动态的话就需要动态库，所以我们需要向根文件系统中添加动态库。在 rootfs 中创建一个名为“`lib`”的文件夹:  `mkdir lib`

lib 库文件从交叉编译器中获取，前面我们搭建交叉编译环境的时候将交叉编译器存放到了“`/usr/local/arm/`”目录中。交叉编译器里面有很多的库文件，

```sh
cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/*so* ~/kenspace/zd-linux/nfs/rootfs/lib/ -d

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/*.a* ~/kenspace/zd-linux/nfs/rootfs/lib/ -d
```

需要将 `ld-linux-armhf.so.3 -> ld-2.19-2014.08-1-git.so*` 软连接改成真正的**源文件**

```sh
rm -rf ~/kenspace/zd-linux/nfs/rootfs/lib/ld-linux-armhf.so.3

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/ld-linux-armhf.so.3 ~/kenspace/zd-linux/nfs/rootfs/lib/
```

还需要拷贝其他 so 和 .a 文件。

```sh
cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/lib/*so* ~/kenspace/zd-linux/nfs/rootfs/lib/ -d

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/lib/*.a* ~/kenspace/zd-linux/nfs/rootfs/lib/ -d
```

- 向 rootfs 的“usr/lib”目录添加库文件

在 rootfs 的 usr 目录下创建一个名为 lib 的目录

```sh
cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/usr/lib/*so* ~/kenspace/zd-linux/nfs/rootfs/usr/lib/ -d

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/usr/lib/*.a* ~/kenspace/zd-linux/nfs/rootfs/usr/lib/ -d

# 查看文件夹大小
$ du lib usr/lib -sh
57M     lib
67M     usr/lib
```

- 创建其他文件夹

在根文件系统中创建其他文件夹，如 dev、proc、mnt、sys、tmp 和 root 等

```sh
book@kendall:rootfs$ mkdir dev proc mnt sys tmp root
```

- 根文件系统初步测试

从 ubunut 加载我们前面移植的 zImage 和 dtb，设置 bootcmd 

```sh
# bootargs=console=ttymxc0,115200 root=/dev/mmcblk1p2 rootwait rw
# 设置  ubuntu2018 版本之后需要加上 v3
setenv bootargs 'console=ttymxc0,115200 root=/dev/nfs rw\
nfsroot=192.168.10.100:/home/book/kenspace/zd-linux/nfs/rootfs,proto=tcp,v3 \
ip=192.168.10.50:192.168.10.100:192.168.10.1:255.255.255.0::eth0:off'

saveenv

# 启动
boot

/ # ls
bin      lib      mnt      root     sys      usr
dev      linuxrc  proc     sbin     tmp
```

### 完善根文件系统

进入开发板 kernel

```sh
mkdir /etc
mkdir /etc/init.d

vim /etc/init.d/rcS
sudo chmod +x rcS 
```

```sh
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib:/usr/lib
export PATH LD_LIBRARY_PATH

mount -a
mkdir /dev/pts

mount -t devpts devpts /dev/pts

echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
```

reboot 重启查看是否还提示 `can't run '/etc/init.d/rcS': No such file or directory`。

但是提示：

```
mount: can't read '/etc/fstab': No such file or directory
/etc/init.d/rcS: line 12: can't create /proc/sys/kernel/hotplug: nonexistent directory
```

book@kendall:etc$ sudo vim fstab

```sh
#<file system>	<mount point>	<type>	<options>	<dump>	<pass>
proc	/proc	proc	defaults	0	0
tmpfs	/tmp	tmpfs	defaults	0	0
sysfs	/sys	sysfs	defaults	0	0
```

继续 reboot 重启发现没有出现任何错误提示，但是我们要还需要创建一个文件 `/etc/inittab`

```sh
#etc/inittab
::sysinit:/etc/init.d/rcS
console::askfirst:-/bin/sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a
```

- 第 2 行，系统启动以后运行 /etc/init.d/rcS 这个脚本文件

- 第 3 行，将 console 作为控制台终端，也就是 ttymxc0。

- 第 4 行，重启的话运行/sbin/init

- 第 5 行，按下 ctrl+alt+del 组合键的话就运行/sbin/reboot，看来 ctrl+alt+del 组合键用于重
启系统。

- 第 6 行，关机的时候执行/bin/umount，也就是卸载各个文件系统

- 第 7 行，关机的时候执行/sbin/swapoff，也就是关闭交换分区

`/etc/inittab` 文件创建好以后就可以重启开发板即可，至此！根文件系统要创建的文件就已经
全部完成了

### 软件运行测试

在 ubuntu 下使用 vim 编辑器新建一个 hello.c 文件，在 hello.c 里面输入如下内容：

```c
#include <stdio.h>

int main(void)
{
	while(1) {
	printf("hello world!\r\n");
	sleep(2);
	}
	return 0;
}
```

```sh
arm-linux-gnueabihf-gcc hello.c -o hello

file hello
# 查看 hello 的文件类型以及编码格式

cp hello drivers 拷贝到 drivers
```

进入 kernel

```sh
/ # cd drivers/
/drivers # ./hello 
hello world!
hello world!
```

### 中文测试

可以看出“`中文测试`”这个文件夹显示正常，接着“`touch`”命令在“`中文测试`”文件夹中新建一个名为“`测试文档.txt`”的文件，并且使用 vim 编辑器在其中输入“这是一个中文测试文件”，借此来测试一下中文文件名和中文内容显示是否正常。

在 kernel 中使用“`cat`”命令来查看“`测试文档.txt`”中的内容。

```
/中文测试 # cat 测试文档.txt 
这是一个中文测试文件
```

### 开发板外网连接

```sh
book@kendall:etc$ sudo touch resolv.conf
# 添加如下内容

nameserver 114.114.114.114
nameserver 192.168.10.1
```


reboot 重启开发板，重新 ping www.baidu.com

> 还是无法访问外网



-----
-----


# 第四期 驱动开发

## 配置 vscode 开发环境

> 参考：https://blog.csdn.net/lizy_fish/article/details/106385958

打开 c_cpp_properties.json

```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**",
                "/home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/include",
                "/home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/include",
                "/home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/include/generated"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/gcc",
            "cStandard": "c11",
            "cppStandard": "gnu++14",
            "intelliSenseMode": "linux-gcc-x64"
        }
    ],
    "version": 4
}
```

## 字符设备开发基础实验


- 编写 Makefile

```mk
KERNELDIR := /home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga

CURRENT_PATH := $(shell pwd)

obj-m := chardevbase.o

build: kernel_modules

kernel_modules:
	$(MAKE) -C $(KERNELDIR) M=$(CURRENT_PATH) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$(CURRENT_PATH) clean 
```

- 编写字符驱动模块加载和卸载程序

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/io.h>

static int __init chardevbase_init(void)
{
    return 0;
}
static void __exit chardevbase_exit(void)
{
   //出口函数具体逻辑 
}


// 模块的入口与出口
module_init(chardevbase_init);
module_exit(chardevbase_exit);
```

- 编译烧写

make

生成的 chardevbase.ko 文件就是要测试的驱动模块

- 测试 .ko

将编译出来的 .ko 文件复制到自己制作的根文件系统里面，

加载 chardevbase.ko 驱动文件 `insmod chardevbase.ko` 或者 `modprobe chardevbase.ko` 

卸载 .ko 模块 `rmmod chardevbase.ko`

- 设置使用 modprobe 命令

```sh
cd /lib/

mkdir modules
cd modules
mkdir 4.1.15
modprobe   # 缺少什么文件夹就创建
```

去 ubuntu 上拷贝编译出来的 .ko 文件

```sh
book@kendall:1_charDriversBase$ sudo cp chardevbase.ko /home/book/kenspace/zd-linux/nfs/rootfs/lib/modules/4.1.15
```

在 kernel 上执行

```
/lib/modules/4.1.15 # modprobe chardevbase.ko 
modprobe: can't open 'modules.dep': No such file or directory
```

modprobe 提示无法打开“`modules.dep`”这个文件，因此驱动挂载失败了。我们不用手动创建 `modules.dep` 这个文件，直接输入 depmod 命令即可自动生成
modules.dep，有些根文件系统可能没有 depmod 这个命令，如果没有这个命令就只能重新配置 busybox，使能此命令，然后重新编译 busybox。输入“`depmod`”命令以后会自动生成 modules.alias、modules.symbols 和 modules.dep 这三个文件，然后重新使用 modprobe 加载 chrdevbase.ko 。

```c
# depmod
# modprobe chardevbase.ko 
/lib/modules/4.1.15 # lsmod   查看挂载的模块
Module                  Size  Used by    Tainted: G  
chardevbase              672  0 
//可能需要创建 # mkdir /proc/modules

# rmmod chardevbase.ko   卸载模块
```


如果提示这些信息

```
chardevbase: module license 'unspecified' taints kernel.
Disabling lock debugging due to kernel taint
```


需要修改代码，在源码后面添加

```c
MODULE_AUTHOR("kendall");
MODULE_DESCRIPTION("kendall test chardevice");
MODULE_LICENSE("GPL v2"); 
···

再复制 

sudo cp chardevbase.ko /home/book/kenspace/zd-linux/nfs/rootfs/lib/modules/4.1.15

重新加载 chardevbase.ko 

输入命令“`cat /proc/devices`”可以查看当前已经被使用掉的设备号

### 编写完善字符设备代码

#### 注册和注销字符设备

对于字符设备驱动而言，当驱动模块加载成功以后需要注册字符设备，同样，卸载驱动模块的时候也需要注销掉字符设备。

```c
// 注册字符设备
// major: 主设备号
// name: 设备名字
// fops: 设备操作函数集合
static inline int register_chrdev(unsigned int major, const char *name,
                                    const struct file_operations *fops);

// 注销字符设备
// major：要注销的设备号
// name: 设备名字
static inline void unregister_chrdev(unsigned int major, const char *name);
```

- 编写 chardevbase.c 和 chardevbaseAPP.c

- 编译

make

arm-linux-gnueabihf-gcc chardevbaseAPP.c  -o chardevbaseAPP

sudo cp chardevbase.ko chardevbaseAPP ~/kenspace/zd-linux/nfs/rootfs/lib/modules/4.1.15/ -f

进入 kernel

modprobe chardevbase.ko 

lsmod

cat /proc/devices


创建设备节点，然后

```sh
/lib/modules/4.1.15 # mknod /dev/chardevbase c 200 0
/lib/modules/4.1.15 # ./chardevbaseAPP /dev/chardevbase 1

# 查看
/lib/modules/4.1.15 # ls /dev/chardevbase -l
```

“mknod”是创建节点命令，“c”表示这是个字符设备，“200”是设备的主设备号，“0”是设备的次设备号。创建完成以后就会存在 `/dev/chardevbase` 这个文件

卸载 `rmmod chardevbase.ko` 之后，`/dev/chardevbase` 也没有了。

## linux LED 灯驱动实验

## 设备树

可以使用 make dtbs 来编译设备树文件，设备树文件位于

`/home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/arch/arm/boot/dts/imx6ull-alientek-emmc.dts`

对应 kernel 的 `/proc/device-tree/`

编译指定的设备树文件 

```sh
/home/book/kenspace/zd-linux/IMX6ULL/linux/linux-imx-rel_imx_4.1.15_2.1.0_ga/$ make imx6ull-alientek-emmc.dtb 
```

### 自定义节点

```c
// book@kendall:dts$ vim imx6ull

 // 自定义节点
 mytestnode {
     
 }; 

// book@kendall:linux-imx-rel_imx_4.1.15_2.1.0_ga$ make dtbs
```

拷贝并重新启动

cp arch/arm/boot/dts/imx6ull-alientek-emmc.dtb  ~/kenspace/zd-linux/tftpboot/ -f

在 `/proc/device-tree/` 去查看添加的节点是否存在。

### 特殊节点

- aliases 子节点

aliases 节点的主要功能就是定义别名，定义别名的目的就是为了方便访问节点。不过我们一般会在节点命名的时候会加上 label，然后通过 &label 来访问节点，这样也很方便，而且设备树里面大量的使用 &label 的形式来访问节点。

- chosen 子节点

chosen 节点主要是为了 uboot 向 Linux 内核传递数据，重点是 bootargs 参数，属性值和 uboot 的 bootargs 一样。

uboot 在启动内核的时候通过 bootz 80800000 0 83000000 来启动，可以通过在 uboot 源码中搜索 chosen 来查看。

```c
// /home/book/kenspace/zd-linux/IMX6ULL/uboot

//在 common/fdt_support.c 文件中



int fdt_chosen(void *fdt)
{
    int   nodeoffset;
    int   err; 
    char  *str;     /* used to set string properties */

    err = fdt_check_header(fdt);
    if (err < 0) { 
        printf("fdt_chosen: %s\n", fdt_strerror(err));
        return err; 
    }    

    /* find or create "/chosen" node. */
    nodeoffset = fdt_find_or_add_subnode(fdt, 0, "chosen");
    if (nodeoffset < 0) 
        return nodeoffset;                                                                                                                    

    str = getenv("bootargs");   // 获取 bootargs 环境变量的值
    if (str) {
        err = fdt_setprop(fdt, nodeoffset, "bootargs", str, 
                  strlen(str) + 1);
        if (err < 0) { 
            printf("WARNING: could not set bootargs %s.\n",
                   fdt_strerror(err));
            return err; 
        }    
    }    

    return fdt_fixup_stdout(fdt, nodeoffset);
}
```

![](../img/bootz命令执行流程.png)

- compatible 属性

compatible 属性用于将设备和驱动绑定起来。字符串列表用于选择设备所要
使用的驱动程序。compatible 属性的值格式如下所示：
```c
"manufacturer,model"   // manufacturer 表示厂商，model 一般是模块对应的驱动名字
```

- `#address-cells` 和 `#size-cells` 属性

`#address-cells` 和 `#size-cells` 这两个属性可以用在任
何拥有子节点的设备中，用于描述子节点的地址信息。`#address-cells` 属性值决定了子节点 reg 属性中地址信息所占用的字长(32 位)，`#size-cells` 属性值决定了子节点 reg 属性中长度信息所占的字长(32 位)。 `#address-cells` 和 `#size-cells` 表明了子节点应该如何编写 reg 属性值，一般 reg 属性都是和地址有关的内容，和地址相关的信息有两种：起始地址和地址长度



