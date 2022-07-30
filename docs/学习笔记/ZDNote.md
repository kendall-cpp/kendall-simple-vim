
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
  - [构建根文件系统](#构建根文件系统)
    - [配置 busybox](#配置-busybox)
- [第四期 驱动开发](#第四期-驱动开发)
  - [配置 vscode 开发环境](#配置-vscode-开发环境)
  - [环境搭建](#环境搭建)
  - [字符设备开发基础实验](#字符设备开发基础实验)
    - [编写 Makefile](#编写-makefile)
    - [编写字符驱动模块加载和卸载程序](#编写字符驱动模块加载和卸载程序)
    - [编译烧写](#编译烧写)
    - [测试 .ko](#测试-ko)

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

```
setenv bootcmd 'tftp 80800000 zImage;tftp 83000000 imx6ull-alientek-emmc.dtb;bootz 80800000 - 83000000;'

saveenv
```

- 设置默认的 根文件系统， 设置 bootargs


```sh
# onsole=ttymxc0 是 imx6uLL 开发板串口 1 的设备，也就是控制台使用串口 1
# root=根文件系统位置，p2 表示 EMMC 的第二个分区
setenv bootargs 'console=ttymxc0,115200 root=/dev/mmcblk1p2 rootwait rw'
saveenv
```

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

将 imx6ull-14x14-evk-emmc.dts 的 &usdhc2 信息复制到 imx6ull-alientek-emmc.dts 的 &usdhc2 下（覆盖掉原来的），如下所示：

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

直接编译被修改过的设备树

make dtbs

> 注意第一次执行的话需要先需要通过 ./imx6ull-alientek-emmc.sh 来进行编译。



## 构建根文件系统

- 修改 Makefile

```mk
 164 CROSS_COMPILE ?= /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-  
 191 ARCH ?= arm    
```

打开文件 busybox-1.29.0/libbb/printable_string.c，找到函数 printable_string


```c
 31     //  if (c >= 0x7f)
 32     //      break;
 33         s++;


 44                 break;
 45         //  if (c < ' ' || c >= 0x7f)
 46             if (c < ' ')
 47                 *d = '?';                                                                                                                 
 48             d++;
 49         }
```

busybox-1.29.0/libbb/unicode.c

```c
1022 //              *d++ = (c >= ' ' && c < 0x7f) ? c : '?';
1023                 *d++ = (c >= ' ') ? c : '?';                                                                                             
1024                 src++;

1031 //              if (c < ' ' || c >= 0x7f)                                                                                                
1032                 if (c < ' ')
1033                     *d = '?';
1034                 d++;
```

### 配置 busybox

make defconfig

出现 `.config` 就表示配置成功

make menuconfig

book@kendall:busybox-1.29.0$ make install CONFIG_PREFIX=/home/book/kenspace/zd-linux/nfs/rootfs



----
-----


# 第四期 驱动开发

## 配置 vscode 开发环境

打开 c_cpp_properties.json

```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**",
                "/home/book/kenspace/zd-linux/linux-kernel/linux-imx-rel_imx_4.1.15_2.1.0_ga_alientek/include",
                "/home/book/kenspace/zd-linux/linux-kernel/linux-imx-rel_imx_4.1.15_2.1.0_ga_alientek/arch/arm/include",
                "/home/book/kenspace/zd-linux/linux-kernel/linux-imx-rel_imx_4.1.15_2.1.0_ga_alientek/arch/arm/include/generated"
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

## 环境搭建

```
sudo apt-get install nfs-kernel-server rpcbind
```

以后我们可以在开发板上通过网络文件系统来访问 nfs 文件夹，要先配置 nfs，使用如下命令打开 nfs 配置文件 /etc/exports

```
sudo vim /etc/exports
```

## 字符设备开发基础实验

在 linux 内核源码中

```
kernel_source$ vim include/linux/fs.h +1606
```

### 编写 Makefile

```mk
KERNELDIR := /home/book/kenspace/zd-linux/linux-kernel/linux-imx-rel_imx_4.1.15_2.1.0_ga_alientek

CURRENT_PATH := $(shell pwd)

obj-m := chardevbase.o

build: kernel_modules

kernel_modules:
	$(MAKE) -C $(KERNELDIR) M=$(CURRENT_PATH) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$(CURRENT_PATH) clean 
```

### 编写字符驱动模块加载和卸载程序

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

### 编译烧写

make

### 测试 .ko

```sh
cd /home/book/kenspace/zd-linux/linux-kernel/three/uboot-imx-rel_imx_4.1.15_2.1.0_ga_alientek

## 编译 EMMC 核心板
./imx6ull_alientek_emmc.sh 

# 烧录进 SD 卡
ls /dev/sd*
./imxdownload u-boot.bin /dev/sdb
```



----> 在系统环节没做好


