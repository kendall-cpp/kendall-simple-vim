
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

- 先将下载的 boot.img 拷贝到 unpack_boot_ramdisk_script 
- 编译 uboot
- 拷贝 ramdisk 到 `To_shengken_sign/korlan/`
- 编译 kernel
- 用 andl 工具烧录 `Z:\workspace\google_source\eureka\amlogic_sdk\To_shengken_sign\korlan\korlan-p2`


> 将 D:\KendallFile\GoogleHome\internal_master_korlan-eng_309703_korlan-ota-korlan-p2-309703\boot.img 拷贝到 Z:\workspace\google_source\eureka\amlogic_sdk\unpack_boot_ramdisk_script 


- kendall-complie_uboot_kernel.sh u-boot 编译 u-boot
- kendall-unpack_boot_copyRamdisk.sh
- kendall-complie_uboot_kernel.sh kernel  编译 kernel

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

只需关注

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

## 2022年7月26日

参考文档：http://www.wowotech.net/gpio_subsystem/io-port-control.html

检索记录：

```sh
u-boot/drivers/pinctrl/meson/pinctrl-meson-axg.c
```

 Meson 系列的 SOC 有两个pinctrl 控制器，分别是： pinctrl_aobus 和 pinctrl_periphs
 
- pinctrl_aobus -- AO domain
- pinctrl_periphs -- EE domain

设备树文件

> kernel/arch/arm/dts/meson-a1-a113l-korlan.dts
> kernel/arch/arm/boot/dts/meson.dtsi

-----

## 2022年8月5日

- 培训结课作业：完成 a5_amlogictest bps 添加，并提交到 girrit


## **uboot 编译脚本流程**

> ./To_shengken_sign/main.sh

- main.sh

```sh
# ./main.sh  /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/ u-boot korlan p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
uboot_compile() {
  ./build_bl2.sh ${COMPILE_PRO_VER_BOARD_NAME} ../u-boot ${Release_macro}  
  # COMPILE_PRO_VER_BOARD_NAME = korlan-p2
  # Release_macro = release
  # ./build_bl2.sh korlan-p2 ../u-boot release

  ./build_bl31.sh ${COMPILE_PRO_VER_BOARD_NAME} ../u-boot  ${Release_macro}
  # ./build_bl31.sh korlan-p2 ../u-boot release

  ./build_bl32.sh ${COMPILE_PRO_VER_BOARD_NAME} ../u-boot  ${Release_macro}
  # ./build_bl32.sh korlan-p2 ../u-boot release

   ./build_uboot.sh ${COMPILE_PRO_VER_BOARD_NAME}  ${CHROME_DIR}  ${Release_macro}  
   # ./build_uboot.sh korlan-p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome release
}
```

- build_bl2.sh

> 完成 DDR 的初始化

```sh
case $product in    # product=$1=korlan-p2
  # 所以走的是  korlan*)

# 会生成一个 bl2.bin 然后拷贝到 u-boot/fip/a1/

# 然后执行 plat/a1/ddr/gen_ddr_fw.sh 去写 fw_new 文件，完成 DDR fw 生成

cp ./aml_ddr.fw ../u-boot/fip/a1/

```

- build_bl31.sh

```sh
# 生成 bl131.img 并拷贝到 u-boot/fip/c2/
cp -v build/c2/release/bl31.img ../u-boot/fip/c2/
```

- build_bl32.sh

```sh
# 生成一个 bl32.img 并拷贝到 u-boot/fip/a1
cp -v out/bl32.img ../u-boot/fip/${PLATFORM_FLAVOR}/
```

- build_uboot.sh

> BL33 一般指 uboot，一般通过它最终启动操作系统内核

```sh
# 进入 building_uboot 函数
# soc_family_name=a1
# local_name=a1_korlan
# rev=p2
# board_name=korlan-p2
# cfg_suffix=
building_uboot a1 a1_korlan p2 $board $dbg_flag  # $board=korlan-p2 $dbg_flag=release

config=${local_name}_${rev}${cfg_suffix} # config=a1_korlan_p2

./mk ${config} --board_name $board_name --bl2 fip/${soc_family_name}/bl2.bin --bl30 fip/${soc_family_name}/bl30.bin --bl31 fip/${soc_family_name}/bl31.img --bl32 fip/${soc_family_name}/bl32.img $5
# ./mk a1_korlan_p2 --board_name korlan-p2 --bl2 fip/a1/bl2.bin --bl30 fip/a1/bl30.bin --bl31 fip/a1/bl31.img --bl32 fip/a1/bl32.img release
# 这行命令主要的工作时 source 前面所有的 脚本

local bootloader_path=${workspace_path}/vendor/amlogic/${product}/prebuilt/${folder}
# bootloader_path=/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/korlan/prebuilt/bootloader
# board = korlan-p2

cp fip/build/bl2_new.bin ${bootloader_path}/bl2_new.bin.${board}
cp fip/build/bl31.img ${bootloader_path}/bl31.img.${board}
cp fip/build/bl32.img ${bootloader_path}/bl32.img.${board}
cp fip/build/bl33.bin ${bootloader_path}/bl33.bin.${board}

# 拷贝ddr bin用于eureka源下的引导加载程序签名
# 删除vendor/amlogic下的ddr文件的硬代码
cp fip/${soc_family_name}/aml_ddr.fw ${bootloader_path}
```

-----

> **至目前为止 u-boot 编译完成**

------

## **kernel 编译脚本流程**

> ./To_shengken_sign/main.sh

- main.sh

```sh
# ./main.sh /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/ aaa korlan p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome
kernel_compile()
{
  cd kernel/
    ./build_kernel.sh ${COMPILE_PRO_VER_BOARD_NAME}  ${CHROME_DIR}
    #  ./build_kernel.sh korlan-p2  /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome

    cd ${CURRENT_DIR}
    # CURRENT_DIR=/mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/To_shengken_sign

    korlan_sign ${CHROME_DIR} ${OUTPUT_SIGNED_DIR}
    korlan_sign /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome korlan/korlan-p2

  # 开始通过这两个脚本对 uboot 和 kernel 进行签名
  # ./build-bootimg-sign_venus.sh
  # ./ssign-uboot_korlan.sh
}
```

**编译 kernel 脚本（不签名）**

- build_kernel.sh

```sh
build_kernel ${kernel_dir} ${board}_defconfig
# build_kernel /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/kernel korlan-p2_defconfig

function build_kernel()
run_kernel_make $cross_compile $cpu_num $arch $defconfig_file_name
# run_kernel_make ../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- 40 arm64 korlan-p2_defconfig

# make kernel 并设置 CONFIG_DEBUG_SECTION_MISMATCH=y
make CLANG_TRIPLE=$clang_triple CC=$cc_clang CROSS_COMPILE=$1 ARCH=$3 -j$2 $4 CONFIG_DEBUG_SECTION_MISMATCH=y

# 再编译 all
run_kernel_make $cross_compile $cpu_num $arch all

# 编译设备树
dtb_file_name=${board}.dtb
# dtb_file_name=korlan-p2.dtb
# path_to_dtb_file=arch/arm64/boot/dts/amlogic/korlan-p2.dtb
build_dtb ${kernel_dir} ${dtb_file_name}
# build_dtb /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/kernel korlan-p2.dtb

function build_dtb()
run_kernel_make $cross_compile $cpu_num $arch $dtb_file_name
# run_kernel_make $cross_compile 40 arm64 korlan-p2.dtb

pack_kernel $path_to_dtb_file ${product} ${board}
# path_to_dtb_file=  product=korlan board=korlan-p2 fctname=fct

pack_kernel() 
cat ${compressed_kernel} ${dtb_file} >> ${packed_kernel}
# cat ${compressed_kernel} korlan-p2.dtb >> ./arch/arm64/boot/kernel.korlan.gz-dtb.korlan-p2

# 编译工厂kernel

path_to_fct_dtb_file=arch/arm64/boot/dts/amlo gic/${fct_dtb_file_name}
# path_to_fct_dtb_file=arch/arm64/boot/dts/amlogic/fct_korlan-p2.dtb
build_dtb ${kernel_dir} ${fct_dtb_file_name}
# build_dtb ${kernel_dir} arch/arm64/boot/dts/amlogic/fct_korlan-p2.dtb
pack_kernel $path_to_fct_dtb_file ${product} ${board} ${fctname}
# pack_kernel arch/arm64/boot/dts/amlogic/fct_korlan-p2.dtb korlan korlan fct

pack_kernel() 
cat ${compressed_kernel} ${dtb_file} >> ${packed_kernel}
# cat ${compressed_kernel} arch/arm64/boot/dts/amlogic/fct_korlan-p2.dtb >> ./arch/arm64/boot/fct_kernel.korlan.gz-dtb.korlan-p2


 cp ${bootdir}/kernel.${product}.gz-dtb.${board} \
        ${kernel_path}
# cp ./arch/arm64/boot/kernel.korlan.gz-dtb.korlan-p2 /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/korlan/prebuilt/kernel                
cp ${path_to_dtb_file} ${kernel_path}/${board}.dtb
# cp arch/arm64/boot/dts/amlogic/korlan-p2.dtb /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/korlan/prebuilt/kernel/korlan-p2.dtb
cp ${bootdir}/${fctname}_kernel.${product}.gz-dtb.${board}  \
    ${fct_kernel_path}/kernel.${product}.gz-dtb.${board}
# cp ./arch/arm64/boot/fct_kernel.korlan.gz-dtb.korlan-p2  /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic/korlan/prebuilt/factory/kernel/kernel.korlan.gz-dtb.korlan-p2
```


## 播放音频测试

开启 kernel 模式下，window 上，push 上去

```sh
adb push .\the-stars-48k-60s.wav /data/
```

驱动源码 

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/kernel$ ls sound/soc/amlogic/auge/tdm.c 

# 更改代码

# 到 kernel
dmesg  -n 8   # 开 log
amixer cset numid=2 150  # 修改音量
amixer cget numid=2       # 查看音量
aplay -Dhw:0,0 /data/the-stars-48k-60s.wav   # 播放  -Dhw:0,0 声卡和 device
```