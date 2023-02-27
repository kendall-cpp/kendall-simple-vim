# kernel Kconfig defconfig .config

**一般情况：**

- defconfig 一般在arch/arm64/configs/目录下，是一个没有展开的内核配置，需要配合Kconfig展开成 .config

- 从 defconfig 到 `.config` 不是简单的复制操作，而是 make ARCH=arm64 defconfig

- `.confg` 也不是直接拷贝成 defconfig ，而是使用 make ARCH=arm64 savedefconfig

正确使用和保存deconfig的流程：
- 1. 要修改在 arch/arm/configs 下的文件 xxx_defconfig （芯片官网） （编译时会去读取 Kconfig 找到 xxx_defconfig)
- 2. make ARCH=arm64 xxx_defconfig 会生成 `.config` 文件
- 3. make ARCH=arm64 menuconfig 修改配置后保存（设置 `.config`）
- 4. make ARCH=arm64 savedefconfig 生成 defconfg 文件
- 5. cp defconfig arch/arm/configs/xxx_defconfig 保存
这样保存的 defconfig 文件，配置最小化，且日后能恢复成 `.config` 。

> make menuconfig ---- 从Kconfig中读出配置菜单 保存到 `.config`

## 以添加一个具体驱动为例

- 找到 arch/arm64/configs/aplex_cmi_aa158_defconfig（这个可以从芯片官网下载）
- 修改配置
- 编译配置

make aplex_cmi_aa158_defconfig ARCH=arm64

> 就是把 arch/arm64/configs/aplex_cmi_aa158_defconfig 里面的配置写到了 Linux 代码目录下的 .config 文件里面。

- 执行 make menuconfig ARCH=arm64 , make menuconfig 操作就是把 .config 文件里面的配置读取出来，然后显示在一个可视化的界面里，在可视化界面修改后会重新写会到 .config 中。

- 保存配置 make savedefconfig  ARCH=arm64

> 执行完毕之后，会生成一个保存的配置文件为： `defconfig`

- 再把 defconfig 文件配置覆盖先前的配置

cp  defconfig  arch/arm64/configs/aplex_cmi_aa158_defconfig -rf 

## Amlogic google config

和普通的defconfig不同，Amlogic 的 defconfig 是没有隐藏依赖的，直接 make menuconfig 生成 .config , 然后和 defconfig 对比，然后拷贝即可，使用 build_kernel 编译的时候会去 diff defconfig 和 `.config` 。

- make menuconfig 修改
- 编译一遍
- vim -d 修改 .config 和 defconfig
- 再编译

---

# 设备树

在Linux 2.6中， ARM架构的板极硬件细节过多地被硬编码在 `arch/arm/plat-xxx和arch/arm/mach-xxx` 中，采用**设备树**后，许多硬件的细节可以直接通过设备树传递给 Linux，而不再需要在内核中进行大量的冗余编码。

## 设备树中 DTS、DTC 和 DTB 的关系

- DTS：.dts 文件是设备树的源文件。由于一个SoC可能对应多个设备，这些 .dst 文件可能包含很多共同的部分，共同的部分一般被提炼为一个 .dtsi 文件，这个文件相当于C语言的头文件。
- DTC：DTC是将.dts 编译为 .dtb 的工具，相当于 gcc。
- DTB：.dtb文件是 .dts 被 DTC 编译后的二进制格式的设备树文件，它可以被 linux 内核解析。

设备节点的标准属性

### compatible 属性

compatible 属性也叫做“兼容性”属性，compatible 属性用于将设备和驱动绑定起来。字符串列表用于选择设备所要使用的驱动程序。

```c
"manufacturer,model"
```

- manufacturer : 表示厂商；
- model : 一般是模块对应的驱动名字。

比如 `imx6ull-alientek-emmc.dts` 中 sound 节点是 I.MX6U-ALPHA 开发板的音频设备节点，I.MX6U-ALPHA 开发板上的音频芯片采用的欧胜(WOLFSON)出品的 WM8960，sound 节点的 compatible 属性值如下：

```c
compatible = "fsl,imx6ul-evk-wm8960","fsl,imx-audio-wm8960";
```

sound 设备首先会使用第一个属性值在 Linux 内核里面查找，看看能不能找到与之匹配的驱动文件；

如果没找到，就使用第二个属性值查找，以此类推，直到查到到对应的驱动程序 或者 查找完整个 Linux 内核也没有对应的驱动程序为止。

```c
// ./sound/soc/fsl/imx-wm8960.c

static const struct of_device_id imx_wm8960_dt_ids[] = { 
  { .compatible = "fsl,imx-audio-wm8960", },
  { /* sentinel */ }                
};                                  
MODULE_DEVICE_TABLE(of, imx_wm8960_dt_ids);
                                    
static struct platform_driver imx_wm8960_driver = { 
  .driver = {                       
    .name = "imx-wm8960",           
    .pm = &snd_soc_pm_ops,          
    .of_match_table = imx_wm8960_dt_ids,
  },                                
  .probe = imx_wm8960_probe,        
  .remove = imx_wm8960_remove,   
};                                  
module_platform_driver(imx_wm8960_driver);
```

一般驱动程序文件都会有一个 OF 匹配表，此 OF 匹配表保存着一些 compatible 值，如果设备节点的 compatible 属性值和 OF 匹配表中的任何一个值相等，那么就表示设备可以使用这个驱动。数组 imx_wm8960_dt_ids 就是 `imx-wm8960.c` 这个驱动文件的匹配表，此匹配表只有一个匹配值“fsl,imx-audio-wm8960”。如果在设备树中有哪个节点的 compatible 属性值与此相等，那么这个节点就会使用此驱动文件。此行设置 `.of_match_table` 为 `imx_wm8960_dt_ids` ，也就是设置这个 platform_driver 所使用的 OF 匹配表。

### model 属性

一般 model 属性描述设备模块信息，比如名字什么的 ,

```c
model = "Samsung S3C2416 SoC";
```


### `#address-cells` 和 `#size-cells` 属性

这两个属性的值都是无符号 32 位整形，`#address-cells` 和 `#size-cells` 这两个属性可以用在任何拥有子节点的设备中，用于**描述子节点的地址信息**。

- `#address-cells` 属性值决定了子节点 reg 属性中地址信息所占用的字长(32 位)，
- `#size-cells` 属性值决定了子节点 reg 属性中长度信息所占的字长(32 位)。
  

`#address-cells` 和`#size-cells` 表明了子节点应该如何编写 reg 属性值，一般 reg 属性都是和地址有关的内容，和地址相关的信息有两种：起始地址和地址长度，reg 属性的格式一为：

```
reg = <address1 length1 address2 length2 address3 length3……>
```

每个“address length”组合表示一个地址范围，其中 address 是起始地址，length 是地址长度，`#address-cells` 表明 address 这个数据的起始地址，`#size-cells` 表明 length 这个数据所占用的字长.

例如一个64位的处理器：

```c
soc {
    #address-cells = <2>;  // 两个地址
    #size-cells = <1>;    // 1 代表一个32位
    serial {
        compatible = "xxx";
        reg = <0x4600 0x5000 0x100>;  /*地址信息是：0x00004600 00005000,长度信息是：0x100*/
        };
};
```

#### reg 属性

reg 属性的值一般是(address，length)对。reg 属性一般用于描述设备地址空间资源信息，一般都是某个外设的寄存器地址范围信息。比如 

```c
uart1: serial@02020000 { 
  ...
  reg = <0x02020000 0x4000>;
}
```

其中 uart1 的父节点 `aips1: aips-bus@02000000` 设置了`#address-cells = <1>、#size-cells = <1>`，因此 reg 属性中 `address=0x02020000，length=0x4000` 。


> 其他属性学习参考： https://zhuanlan.zhihu.com/p/425420889



----

# kernel 源码结构体里的元素前面有一点“.”

> 参考：http://blog.chinaunix.net/uid-29033331-id-3811134.html

例如：

```c
//gceSTATUS _AdjustParam(IN gcsPLATFORM *Platform,OUT gcsMODULE_PARAMETERS *Args)
//这些函数定义在上面

static gcsPLATFORM_OPERATIONS default_ops =
{
    .adjustParam   = _AdjustParam,
    .getPower  = _GetPower,
    .reset = _Reset,
    .putPower = _DownPower,
    .setPower = _SetPower,
    .getPowerStatus = _GetPowerStatus,
    .setPolicy = _SetPolicy,
};
```

这与我们之前学过的结构体初始化差距甚远。其实这就是前面所说的指定初始化在Linux设备驱动程序中的一个应用，它源自ISO C99标准。以下我摘录了C Primer Plus第五版中相关章节的内容，从而就可以很好的理解2.6版内核采用这种方式的优势就在于由此初始化不必严格按照定义时的顺序。这带来了极大的灵活性，其更大的益处还有待大家在开发中结合自身的应用慢慢体会。 已知一个结构，定义如下

```c
struct book { 
    char title[MAXTITL]; 
    char author[MAXAUTL]; 
    float value; 
};
```

C99支持结构的指定初始化项目，其语法与数组的指定初始化项目近似。只是，结构的指定初始化项目使用点运算符和成员名（而不是方括号和索引值）来标识具体的元素。例如，只初始化book结构的一个成员value，可以这样做： 

```c
struct book surprise = { .value = 10.99 }; 
```

可以按照任意的顺序使用指定初始化项目： 

```c
struct book gift = { 
    .value = 25.99, 
    .author = "James Broadfool", 
    .title = "Rue for the Toad"
};
```

正像数组一样，跟在一个指定初始化项目之后的常规初始化项目为跟在指定成员后的成员提供了初始值。

---

# makefile 中符号


- "="

“=”是最普通的等号，然而在Makefile中确实是最容易搞错的赋值等号。使用”=”进行赋值，变量的值是整个makefile中最后被指定的值

```sh
VIR_A = A
VIR_B = $(VIR_A) B
VIR_A = AA
```

经过上面的赋值后，最后VIR_B的值是AAB，而不是AB。在make时，会把整个makefile展开，拉通决定变量的值

- “:=”

”:=”就表示直接赋值，赋予当前位置的值

```sh
VIR_A := A
VIR_B := $(VIR_A) B
VIR_A := AA
```

最后，变量VIR_B的值是AB，即根据当前位置进行赋值。因此相比于”=”，”:=”才是真正意义上的直接赋值。

- “?=”

“？=”表示如果该变量没有被赋值，则赋予等号后的值。举例：

```sh
 VIR ?= new_value
```

如果VIR在之前没有被赋值，那么现在VIR的值就为new_value

```sh
VIR := old_value
VIR ?= new_value
```

这种情况下，VIR 的值就是 old_value

- “+=”

“+=”和平时写代码的理解是一样的，表示将等号后面的值添加到前面的变量上

## makefile 打印调试

```sh
# info 是不带行号的
$(info “here is debug")

# warning 是带行号的
$(warning “here is debug")

# error 停止当前makefile的编译
$(error “here is debug")
```

---

# Buildroot记录


## 编译BuildRoot

### 整体编译

```sh
source setenv.sh 
# 选择板子
make
```

### 单独编译

```sh
# 编译uboot
# 比如用409的bootloader
ls bl33/v2019/board/amlogic/defconfigs/c3_aw409_defconfig 
# 编译
uboot-repo$ ./mk c3_aw409_av400

# 编译kernel
# buildRoot_C3$ make linux-dirclean 一般不用清理
buildRoot_C3$ make linux-rebuild  

# 编译uboot
# buildRoot_C3$ make uboot-dirclean 一般不用清理
buildRoot_C3$ make uboot-rebuild 

make  # 打包成大的 img
make show-targets # 查看所有package

make menuconfig    # 整个工程 menuconfig
make linux-menuconfig # kernel menuconfig
make linux-savedefconfig # 保存到 output/linux-kernel/defconfig
```


## buildroot 找到配置文件

比如找到 av400 kernel使用的是哪个配置文件

在 buildroot 下找到 sourse select 对应文件名的配置文件

```sh
a5_av400_spk_a6432_release_defconfig 
  -- #include "a5_av400_spk.config"

vim configs/amlogic/a5_av400_spk.config 

#include "a5_speaker.config"

#include "a5_base.config"  

# 找到
BR2_LINUX_KERNEL_DEFCONFIG="meson64_a64_smarthome"  
```

所以 kernel 使用的配置文件是 ./arch/arm64/configs/meson64_a64_smarthome_defconfig


通过 make linux-menuconfig 生成的配置文件在 output/a5_av400_spk_a6432_release/build/linux-amlogic-5.4-dev/.config


make linux-savedefconfig

保存到  ./output/a5_av400_spk_a6432_release/build/linux-amlogic-5.4-dev/defconfig

找到对应修改的配置(比如 UAC )复制到 kernel/aml-5.4/arch/arm64/configs/meson64_a64_smarthome_defconfig



## buildroot-output目录

- build 包含所有的源文件，包括 Buildroot 所需主机工具和选择的包，这个目录包含所有 模块源码。

- host 主机端编译需要的工具包括交叉编译工具

- images 含压缩好的根文件系统镜像文件

- staging 这个目录类似根文件系统的目录结构，包含编译生成的所有头文件和库，以及其他开发文件，不过他们没有裁剪，比较庞大，不适用于目标文件系统。

- target 包含完整的根文件系统，相比 `staging/`，它没有开发文件，不包含头文件，二进制文件也经过 strip 处理。

进行编译时，Buildroot 根据配置，会自动从网络获取相关的软件包，包括一些第三方库，插件，实用工具等，放在`dl/`目录。

软件包会解压在 `output/build/` 目录下，然后进行编译

如果要修改软件包的源码，可以通过打补丁的方式进行修改，补丁集中放在 `package/` 目录，Buildroot 会在解压软件包时为其打上相应的补丁

### output一些配置文件

1. 直接删除源码包，例如我们要重新编译 openssh，那么可以直接删除 `output/build/openssh-vesion` 文件夹，那么当你 make 的时候，他就会自动从 dl 文件夹下，解压缩源码包，并重新安装

2. 也是以 openssh 为例子，如果我们不想重新编译，只想重新配置，也就是 `./configure` ，

- 我们可以直接删除 output/build/openssh-version 目录下的 `.stamp_configured`
- 如果你只是想重新安装可以删除 `.stamp_target_install`
- 重新 make 可以删除 `.stamp_built`

```sh
.stamp_configured,          此文件表示已经配置过
.stamp_downloaded,          此文件表示源码已经下载过，没有此文件会重新下载
.stamp_patched,             此文件表示已经打过补丁
.stamp_extracted            此文件表示已经解压过
.stamp_builted              此文件表示源码已经编译
.stamp_target_installed     此文件表示软件已经安装过
```

注意：修改代码后（不是修改 output 目录下的），不用运行 linux-dirclean，只用 linux-rebuild 即可。Buildroot 会 rsync 将你外部的源码同步到 output/build 并且编译，并且不会删掉上次编译的缓存文件，自动只编译你修改的部分。

## buildroot 根文件系统设置启动命令

busybox 根文件系统是在/etc/init.d/rcS 里面添加自启动相关命令的

```sh
for i in /etc/init.d/S??* ;do

     # Ignore dangling symlinks (if any).
     [ ! -f "$i" ] && continue

     case "$i" in
    *S02overlayfs)
        continue
        ;;
      *S40network|*S41dhcpcd)
        # skip network and dhcpcd if netplugd enabled
        killall -0 netplugd 2> /dev/null
        if [ ! $? -eq 0 ]; then
          $i start
        fi
        ;;
    *.sh)
        # Source shell script for speed.
        (
        trap - INT QUIT TSTP
        set start
        . $i
        )
        ;;
    *)
        # No sh extension, so fork subprocess.
        $i start
        ;;
    esac
done
```

从上面可以看出，rcS 默认会在 /etc/init.d 目录下查找所有以‘S’开头的脚本，然后依次执行这些脚本。s所以我们可以自己创建一个以‘S’开头的自启动脚本文件，比如我创建一个名为 S90start_adb.sh 的自启动文件，**一般以数字命名决定执行顺序**， 命令如下：

```sh
touch S90start_adb.sh
vim S90start_adb.sh
chmod 777 S90start_adb.sh
```

然后在 S90start_adb.sh 中天添加需要执行的命令，比例

```sh
mkdir /lsken00/
touch /lsken00/test.txt
echo "lsken00 --- --- test"
```

最后重新 make 编译烧录启动板子，观察

```sh
# ls lsken00/
test.txt
```


## 修改 buildroot dl 下载路径

```sh
vim buildroot/Config.in

# 找到BR2_DL_DIR变量的设置
# 改变路径的方法：
# default  "$(TOPDIR)/dl"
string "Download dir"  
-default "$(TOPDIR)/dl"
+default "../../buildroot_dl" 
```


## buildroot 修改 defconfig

> 以 a5_av400 为例

首先找到 kernel 的 defconfig 文件

```sh
# 在buildroot 中
# ./configs/a5_av400_spk_a6432_release_defconfig
a5_av400_spk_a6432_release_defconfig 
  -- #include "a5_av400_spk.config"

vim configs/amlogic/a5_av400_spk.config 

#include "a5_speaker.config"

#include "a5_base.config"  

# 找到
BR2_LINUX_KERNEL_DEFCONFIG="meson64_a64_smarthome"  
```

所以 kernel 使用的配置文件是 ./arch/arm64/configs/meson64_a64_smarthome_defconfig


通过 make menuconfig 生成的配置文件在 output/a5_av400_spk_a6432_release/build/linux-amlogic-5.4-dev/.config

linux-amlogic-5.4-dev/.config 可以找到 BR2_LINUX_KERNEL_DEFCONFIG

linux-amlogic-5.4-dev/.config    可以找到 UAC2

- 开启 uac  声卡

make linux-menuconfig

```sh
Device Drivers  --->

[*] USB support  --->

<*>   USB Gadget Support  ---> 

[*]     Audio Class 2.0 

CONFIG_USB_CONFIGFS_F_UAC2=y
```

make linux-savedefconfig

- 保存到  ./output/a5_av400_spk_a6432_release/build/linux-amlogic-5.4-dev/defconfig

- 然后将 defconfig 的修改添加到 aml-5.4/arch/arm64/configs/meson64_a64_smarthome_defconfig

## config 和 mk 文件

比如

 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/configs/amlogic/npu_driver_k5.4.config 

 这里会配置全局的局部变量，给 package/amlogic 下的各个 package 用

 比如给 `vim package/amlogic/npu/npu.mk`  使用

```sh
 cd $(@D);./aml_buildroot.sh $(KERNEL_ARCH) $(LINUX_DIR) $(TARGET_KERNEL_CROSS)
#  cd /mnt/fileroot/shengken.lin/workspace/a5_buildroot/output/a5_av400_a6432_release/build/npu-1.0;./aml_buildroot.sh arm64 /mnt/fileroot/shengken.lin/workspace/a5_buildroot/output/a5_av400_a6432_release/build/linux-amlogic-5.4-dev /mnt/fileroot/shengken.lin/workspace/a5_buildroot/buildroot/../toolchain/gcc/linux-x86/aarch64/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
```


----

# proc文件系统

## 什么是proc文件系统

- proc是虚拟文件系统，虚拟的意思就是 proc 文件系统里的文件不对应硬盘上任何文件，我们用去查看 proc 目录下的文件大小都是零；
- proc 文件系统是开放给上层了解内核运行状态的窗口，通过读取 proc 系统里的文件，可以知道内核中一些重要数据结构的数值，从而知道内核的运行情况，也可以方便调试内核和应用程序；
- proc 文件系统的思路：在内核中构建一个 虚拟文件系统/proc，内核运行时将内核中一些关键的数据结构以文件的方式呈现在`/proc`目录中的一些特定文件中，这样相当于将不可见的内核中的数据结构以可视化的方式呈现给内核的开发者.

## 常见的proc文件介绍

| 文件名  | Describe |
| :---: | :------------------------------- |
| /proc/cmdline | 查看内核的启动参数 |
| /proc/cpuinfo | 查看CPU的信息 |
| /proc/devices | 查看内核中已经注册的设备 |
| /proc/filesystems | 内核当前支持的文件系统类型 |
| /proc/interrupts | 中断的使用及触发次数，调试中断时很有用 |
| /proc/misc | 内核中注册的misc类设备 |
| /proc/modules | 已经加载的模块列表，对应lsmod命令 |
| /proc/partitions | 系统的分区表 |
| /proc/version | 当前正在运行的内核版本 |
| 数字（PID） | 数字的文件夹都是相应的进程 |
| /proc/mounts | 已加载的文件系统的列表，对应mount命令 |
| /proc/meminfo | 内核的内存信息 |
| /proc/fb | 内核中注册的显示设备 |
| buddyinfo | 用于诊断内存碎片问题。 |
| bus | 已安装的总线 |
| cgroups | 信息汇总，字段 subsys_name; hierarchy; num_cgroups; enabled |
| stat | 全面统计状态表，CPU内存的利用率等都是从这里提取数据。对应ps命令


> 其余的: https://blog.csdn.net/fly0512/article/details/122362624

- 查看进程调用栈信息 |

```sh
/proc/1818 # cd ..
/proc # cat 1818/stack 
[<0>] __switch_to+0x12c/0x148
[<0>] futex_wait_queue_me+0xd8/0x144
[<0>] futex_wait+0x120/0x2d0
[<0>] do_futex+0x128/0x7b4
[<0>] __arm64_sys_futex+0xa8/0x1d0
[<0>] el0_svc_common+0x9c/0x114
[<0>] el0_svc_handler+0x2c/0x38
[<0>] el0_svc+0x8/0x14c
[<0>] 0xffffffffffffffff
```

## 和sys文件系统的比较

- (1) proc 文件系统主要是用来调试内核，在内核运行时可以知道内核中一些重要的数据结构的值，一般都是读，很少写；
- (2) proc 文件系统出现的比 sys 文件系统早，proc 文件系统的目录结构比较乱，在 proc 文件系统下面有很多文件夹，比如一个进程就有一个文件夹，现在内核越来越复杂，支持的设备类型也越来越多，显得很混乱；于是又开发出了 sys 系统，sys 系统可以说是 proc 的升级，将来用 sys 系统会是主流；
- (3) proc 文件系统和 sys 文件系统都是虚拟系统，并且有对应关系，比如"`/proc/misc`"对应于"`sys/class/misc`"下面的设备，都是描述 misc 类设备的；

---

# GPIO 子系统的作用

芯片内部有很多引脚，这些引脚可以接到 GPIO 模块，也可以接到 I2C 模块，通过 Pinctrl 子系统来选择引脚的功能（mux function），配置引脚。当一个引脚被复用为 GPIO 功能时，我们可以去设置它的方向（输入或者输出），设置/读取 它的值。GPIO 可能是芯片自带的，也可能是通过 I2C、SPI 接口扩展。

![](https://img-blog.csdnimg.cn/1aa6ca3fb83a40e1a59aaa51aa5223f9.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5Lmg5oOv5bCx5aW9eno=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 通用功能

- 可以设为输出，让它输出高低电平
- 可以设为输入，读取引脚当前电平
- 可以用来触发中断

对于芯片自带的 GPIO，它的访问速度很快，可以在获得 spinlocks 的情况下操作它。但是，对于通用 I2C、SPI 等接口扩展的 GPIO，访问它们时可能导致休眠，所以这些“GPIO Expander”就不能在获得 spinlocks 的情况下使用。

linux 内核中提供了 GPIO 子系统，我们在驱动代码中使用 GPIO 子系统的 API 函数去控制 GPIO


> 深入理解 gpio: http://www.wowotech.net/sort/gpio_subsystem

# pinctrl 子系统概念

一个设备（URAT)有两个状态，默认和休眠状态，默认状态时将对应引脚设置为 这个 URAT 功能，休眠状态时将引脚设置为普通的 GPIO 功能。

```c
device {
	pinctrl-names = "default", "sleep";   //1.设置设备的两种状态
	pinctrl-0 = <&state_0_node_a>; //设置0状态的名字是 default，对应的引脚在 pinctrl-0里面定义
	//这个节点描述在这个状态下要怎么做，这些节点位于 pinctrl 节点里面
	pinctrl-1 = <&state_1_node_a>; //第1状态的名字是sleep，对应的引脚在pinctrl-1里定义
};

picontroller {
	state_0_node_a {
		function = "urat0";
		groups = "u0rxtx", "u0rtscts";
	}
	state_1_node_a {
		function = "gpio";
		groups = "u0rxtx", "u0rtscts";
	}
};
```

- 当这个设备属于 default 状态时，会使用 state_0_node_a 这个节点来配置引脚。也就是会把这一组引脚配置成 urat0 功能
- 当这个设备属于 sleep 状态时，会使用 state_1_node_a 这个节点来配置引脚，也就是会把这一组引脚配置成 gpio 功能

所以 state_0_node_a 和 state_1_node_a 的作用就是复用引脚的功能，在内核中这类的引脚成为 pin multiplexing node .


```c
device {
	pinctrl-names = "default", "sleep";   //1.设置设备的两种状态
	pinctrl-0 = <&state_0_node_a>; 
	//这个节点描述在这个状态下要怎么做，这些节点位于 pinctrl 节点里面
	pinctrl-1 = <&state_1_node_a>; 
};

picontroller {
	state_0_node_a {
		function = "urat0";
		groups = "u0rxtx", "u0rtscts";
	}
	state_1_node_a {
		groups = "u0rxtx", "u0rtscts";
		output-high;
	}
};
```

- 当这个设备属于 default 状态时，会使用 state_0_node_a 这个节点来配置引脚。也就是会把这一组引脚配置成 urat0 功能
- 当这个设备属于 sleep 状态时，会使用 state_1_node_a 这个节点来配置引脚，也就是会把这一组引脚配置成 输出高电平

这类节点成为 pin configuration node 。


> **更多参考**： https://www.cnblogs.com/zhuangquan/p/12750736.html

---


# 嵌入式系统的分区

> sonos-openlinux A5-av400

分区是磁盘划分区域的手段，比如我们平时用的 window 系统，通过起始地址和 size 等信息保存至分区表，可以将磁盘分层若干的区域，用于存储不同的内容。嵌入式系统也一样有分区。

## 分区表

> 注意 bootloader的分区表要和 kernel 中的一一对应，否则会导致系统无法启动。

- uboot 中的分区表一般是在 board 文件下先对应板子信号的 `.c` 文件，比如 `a5_av400.c` 。
- kernel 中的分区表一般是在 a`rch/arm64/boot/dts` 文件夹下对应板子型号的 dts ，比如： a5_a113x2_av400_1g.dts

`a5_av400.c` 

```c
static struct mtd_partition normal_partition_info[] = {
	{
	 .name = BOOT_BL2E,
	 .offset = 0,
	 .size = 0,
	  },
	{
	 .name = BOOT_BL2X,
	 .offset = 0,
	 .size = 0,
	  },
	{
	 .name = BOOT_DDRFIP,
	 .offset = 0,
	 .size = 0,
	  },
	{
	 .name = BOOT_DEVFIP,
	 .offset = 0,
	 .size = 0,
	  },  // 签名几个分区 size = 0 表示系统没给对应的分区分配空间
	{
	 .name = "logo",
	 .offset = 0,
	 .size = 2 * SZ_1M,   //表示 logo 分区的大小为 2M
	  },
	{
	 .name = "recovery",
	 .offset = 0,
	 .size = 16 * SZ_1M, 
	  },
	{
	 .name = "boot",
	 .offset = 0,
	 .size = 16 * SZ_1M,  //表示 boot 分区的大小为 16M， boot.img 对应的分区
	  },
	{
	 .name = "system",     // system.img 对应的分区
	 .offset = 0,
	 .size = 64 * SZ_1M,
	  },
/* last partition get the rest capacity */   //最后一个分区将分配剩余全部内存空间
	{
	 .name = "data",
	 .offset = MTDPART_OFS_APPEND,
	 .size = MTDPART_SIZ_FULL,
	  },
};
```

- a5_a113x2_av400_1g.dts

```c

	partitions: partitions{
		parts = <5>;
		part-0 = <&recovery>;
		part-1 = <&misc>;
		part-2 = <&boot>;
		part-3 = <&system>;
		part-4 = <&data>;

		recovery:recovery{
			pname = "recovery";
			size = <0x0 0x2000000>;
			mask = <1>;
		};
		misc:misc{
			pname = "misc";
			size = <0x0 0x800000>;
			mask = <1>;
		};
		boot:boot
		{
			pname = "boot";
			size = <0x0 0x4000000>;
			mask = <1>;
		};
		system:system
		{
			pname = "system";
			size = <0x0 0x40000000>;
			mask = <1>;
		};
		data:data
		{
			pname = "data";
			size = <0xffffffff 0xffffffff>;
			mask = <4>;
		};
	};
```

从上面代码可以看出，系统被分层是个分区，分别是 recovery ，misc，boot，system，data 。



|          | uboot | kernel     |
| -------- | :---: | ---------- |
| recovery |  16M  | 0x2000000  |
| misc     |  2M   | 0x800000   |
| boot     |  16M  | 0x4000000  |
| system   |  64M  | 0x40000000 |
| data     |       |            |

> 对不上？？

## 代码追踪分析

### 获取分区的函数调用栈

```
meson_nfc_probe

  m3_nand_probe

    aml_nand_init

      aml_nand_add_partition

        get_aml_mtd_partition
```

-  U_BOOT_DRIVER

新版的 uboot 和 linux 一样，都支持设备树， uboot  就是通过 U_BOOT_DRIVER 建立一个驱动模型，of_match 来匹配， prebe 函数来识别等。

```c
static const struct udevice_id aml_nfc_ids[] = {
	{ .compatible = "amlogic,meson-nfc" }, // compatible 属性也叫做“兼容性”属性，compatible 属性用于将设备和驱动绑定起来。字符串列表用于选择设备所要使用的驱动程序。
	{}
};

U_BOOT_DRIVER(meson_nfc) = {
	.name	= "meson-nfc",
	.id	= UCLASS_MTD,
	.of_match = aml_nfc_ids,
	.probe = meson_nfc_probe,
};

```

- 通过 of_match 函数找到 "amlogic,meson-nfc" 并绑定驱动和设备

- 然后执行 meson_nfc_probe 函数

- 选择相应的板子（a5_av400_a6432_release）并进行初始化，然后进入 m3_nand_probe 函数

- malloc 并初始化相关结构体

- 走进 aml_nand_init

在这个函数中初始化的时候会通过 aml_nand_add_partition 去添加分区表

  - get_aml_mtd_partition ： 找到并添加分区表
  - get_aml_partition_count ： 计算分区表大小

---

# UAC功能迁移（kernel 4.9-kernel 5.4）


-----

# 文件系统mount流程






# rtos-linuix-rtos 架构

## suspend 流程

## sysfs学习