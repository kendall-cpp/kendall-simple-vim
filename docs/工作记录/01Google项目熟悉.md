
- [2022年7月15日](#2022年7月15日)
  - [编译u-boot和kernel](#编译u-boot和kernel)
  - [打开 uboot 命令行模式](#打开-uboot-命令行模式)
  - [板子和芯片相关型号](#板子和芯片相关型号)
  - [设置显示时间](#设置显示时间)
    - [找到寄存器](#找到寄存器)
    - [bootm要做的事情](#bootm要做的事情)
- [2022年7月18日](#2022年7月18日)
  - [kernel源码目录结构](#kernel源码目录结构)
  - [arch/arm 目录](#archarm-目录)
  - [kernel启动流程](#kernel启动流程)
  - [测试开启 u-boot log 和不开启的时间](#测试开启-u-boot-log-和不开启的时间)
  - [ramdisk.img解包](#ramdiskimg解包)

------

## 2022年7月15日

### 编译u-boot和kernel

- 先将下载的boot.img 拷贝到 unpack_boot_ramdisk_script 
- 编译 uboot
- 拷贝 ramdisk 到 `To_shengken_sign/korlan/`
- 编译 kernel
- 用 andl 工具烧录 `Z:\workspace\google_source\eureka\amlogic_sdk\To_shengken_sign\korlan\korlan-p2`


> 将 D:\KendallFile\GoogleHome\internal_master_korlan-eng_309703_korlan-ota-korlan-p2-309703\boot.img 拷贝到 Z:\workspace\google_source\eureka\amlogic_sdk\unpack_boot_ramdisk_script 


- kendall-complie_uboot_kernel.sh u-boot 编译签名 u-boot
- kendall-unpack_boot_copyRamdisk.sh
- kendall-complie_uboot_kernel.sh kernel  编译签名 kernel

> 生成的文件在 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/To_shengken_sign/korlan/korlan-p2

烧录

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
adnl.exe oem "reset"    #重启
```

### 打开 uboot 命令行模式

```sh
u-boot/board/amlogic/defconfigs/a1_korlan_p2_defconfig

 13 CONFIG_BOOTDELAY=-2  改成 2

106 #CONFIG_LOGLEVEL=4
107 #CONFIG_SPL_LOGLEVEL=4
108 #CONFIG_TPL_LOGLEVEL=4
# 修改
109 CONFIG_LOGLEVEL=7
110 CONFIG_SPL_LOGLEVEL=7
111 CONFIG_TPL_LOGLEVEL=7
```

### 板子和芯片相关型号

- u-boot

> - meson-a1-a113l-korlan.dts
> - arch/arm/mach-meson/board-common.c
> - arch/arm/mach-meson/a


### 设置显示时间

> /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/bl2/bl2$ vim bl2_main.c 

```c
179   serial_puts("\nTE: ");              
180   serial_put_dec(*(unsigned int *)TE_TIMER);  
```

#### 找到寄存器

```c
//bl2/bl2/bl2_main.c
serial_puts("\nTE: ");
serial_put_dec(*(unsigned int *)TE_TIMER);


///mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/bl2$ vim ./plat/a1/include/timer.h
#define TE_TIMER	P_ISA_TIMERE

//plat/a1/include/regs.h
#define P_ISA_TIMERE          (volatile uint32_t *)(SYSCTRL_TIMERE)  

//plat/a1/include/register.h
#define SYSCTRL_TIMERE                             ((0x0041  << 2) + 0xfe005800) 

//修改
// /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/u-boot/arch/arm/lib$ vim bootm.c 
#define SYSCTRL_TIMERE                             ((0x0041  << 2) + 0xfe005800) 
#define P_ISA_TIMERE          (volatile uint32_t *)(SYSCTRL_TIMERE)  
#define TE_TIMER	P_ISA_TIMERE

printf("\nbootm.c kendall ==========>>> kernel time: %u us\n", P_ISA_TIMERE);
```


#### bootm要做的事情

- a 读取头部,把内核拷贝到合适的地方 (0x30008000) 结构为头部(image_header)+真正的内核。
    - ih_load:加载地址 内核运行时要先放在哪里（放在0x30008000）
    - ih_ep：入口地址 运行内核时只要跳转到该地址即可
- b 在 `do_boom_linux()` 中把参数给内核准备好,并告诉内核参数的首地址

- c 在do_boom_linux()中最后使用theKernel () 引导内核. 

## 2022年7月18日

### kernel源码目录结构

> arch:  包含和硬件体系相关的的代码，每种硬件平台占一个相应的目录，如i386,arm, arm64, powerpc,mips等。
> block: 块设备驱动程序I/O调度。
> crypto： 常用的加密和散列算法，还有一些压缩和CRC校验算法。
> documentation：内核各部分的通用解释和注释。
> drivers：设备驱动程序，各个不同的驱动占用一个子目录。
> fs: 所支持的各种文件系统。
> include：头文件，与系统相关的头文件位置放在include/linux子目录下。
> init：内核初始化代码，著名的start_kernel()就位于init/main.c文件中。
> ipc: 进程间通信的代码。
> kernel：内核最核心的部分，包括进程调度，定时器等，和平台相关的一部分代码放在arch/*/kernel 下。
> lib: 库文件代码。
> mm: 内存管理代码，和平台相关的一部分代码放在arch/*/mm目录下。
> net：网络相关的代码，实现各种常见的网络协议。
> scripts：用于配置内核的脚本文件。
> security： 主要是一个SELLinux模块。
> sound： ALSA.OSS  音频设备的驱动核心代码和常用驱动设备。
> usr: 实现用于打包和压缩的cpio等。
> include： 内核API级别头文件

### arch/arm 目录

- `arch/arm/kernel` 目录下的 `head.S` 文件是 linux 系统启动的第一个文件

- `arch/arm/kernel` 目录下的 `trap.c` 文件，对 CPU 的异常进行初始化

- `arch/arm/kernel` 目录下的 `dma.c` ，对 CPU 的 dma 进行管理

- Kconfig 文件里的内容在执 行make menuconfig 时会出现在界面中
  
- configs 目录下是一些默认配置文件，可以用来生成内核需要的配置文件 `.config` ，执行 make menuconfig 也会生成一个 `.config` 文件，.config 文件指导编译时需要编译哪些文件，最终生成的 vmlinux 就是能够运行在该架构下的 linux 内核

- mach-meson 名目录下的文件，描述了该SoC内部硬件资源(如地址、大小等)，mach-Board 文件是描述板子资源的文件。

> 修改 configs 目录下的默认配置文件，生成 `.config` 文件，

### kernel启动流程

参考：https://zhuanlan.zhihu.com/p/456531995?utm_source=wechat_session&utm_medium=social&utm_oi=1270289853625372672

> init/main.c

- start_kernel() 函数开始内核的初始化工作

### 测试开启 u-boot log 和不开启的时间

- 不开启uboot-log：9.291163
- 开启uboot-log：  9.819500


找到：google_source/eureka/amlogic_sdk/kernel/drivers/amlogic/timestamp/meson_timestamp.c

修改

```c
pr_info(" kendall ========>>> Kernel TE entry: %llu\n", meson_timestamp_hw_get(tdev->base));
```


- 关闭 u-boot: 4340981
- 打开 u-boot: 6512568

开启内核的打印时间戳

在编译Linux内核：make menuconfig ---> Kernel hacking -->printk and dmesg options--> show timing information on printks

当选中这个选项后，启动内核，会在日志信息前面加上时间戳。

### ramdisk.img 解包

```sh
mv ramdisk.img ramdisk.img.xz
unxz ramdisk.img.xz 
file ramdisk.img
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

# 2020年7月19日

### 挂载文件系统前后时间

将 ramdisk.img 解压出来修改 init，再重新打包压缩回 ramdisk.img

```sh
# 解压
mv ramdisk.img ramdisk.img.xz
unxz ramdisk.img.xz
cpio -i -F ramdisk.img   #解压cpio

write /dev/kmsg "INIT: early-init entry"

# 打包
find . |cpio -ov -H newc | xz -9  --check=crc32  > ../ramdisk.img

```

kernel 中执行 dmesg 查看日志 -- 带时间戳

修改 kernel/init/do_mounts.c

## 2020年7月20日

- 1 bootloader阶段：bl2,bl31,bl32,bl33(uboot)
  - 4261435652
- 2 kernel 阶段
  - 2.936989@0


- 3 ramdisk init阶段：
	- 1） 挂载文件系统前
    - [    3.416286@0] INIT: mount squashfs /dev/mapper/system /system.ro ro nodev noatime ===> end
	- 2） 挂载文件系统后
    [    4.526793@1] INIT: mount pstore none /sys/fs/pstore kmsg_bytes=8000 ===> end


## 找到 hw_id 怎么来的

```c
[    0.000000@0] Kernel command line: otg_device=1 hw_id=0x04 warm_boot=1 androidboot.reboot_mode=watchdog_reboot androidboot.hardware=korlan-p2 rootfstype=ramfs init=/init console=ttyUSB0,115200 console=ttyS0,115200 no_console_suspend earlycon=aml_uart,0xfe002000 quiet loglevel=7 ramoops.pstore_en=1 ramoops.record_size=0x8000 ramoops.console_size=0x4000 selinux=1 enforcing=0
```


寻找

```c
#define PADCTRL_GPIOX_I                            ((0x0040  << 2) + 0xfe004000)


// ./u-boot/board/amlogic/a1_korlan_p2/a1_korlan_p2.c
  /* read hw id */
  ret = readl(PADCTRL_GPIOX_I);
  hw_id = (ret >> 0) & 0x1F;
    
  snprintf(hw_id_str, sizeof(hw_id_str), "0x%02x", hw_id);
  env_set("hw_id", hw_id_str);
  return 0;
}  
    
U_BOOT_CMD(
  get_board_hw_id, 1, 0, do_get_board_hw_id,
  "get GQ/NQ HW_ID and env_set 'hw_id'\n",                                                                                                  
  "get_board_hw_id"
); 

```
vim bl2/plat/a1/plat_init.c +300

```