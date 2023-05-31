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

以 korlan 添加一个 config 为例

```sh
# 修改  Kconfig； 注意对齐
# 不用修改 korlan-p2_defconfig 
config LSKEN
	tristate "aaaaaaaaaaaaaaaaaaa lsken00"  # 这个就是 menuconfig 中菜单的名字
	#depends on OF_RESERVED_MEM
	default n
	help
		lsken00

# 先根据 korlan-p2_defconfig  生成 .config
make  CLANG_TRIPLE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- CC=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang CROSS_COMPILE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- ARCH=arm64 korlan-p2_defconfig CONFIG_DEBUG_SECTION_MISMATCH=y 

# 设置 meconfig ， 也可以直接省略上步， 这里也会直接生成 .config
make  CLANG_TRIPLE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- CC=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang CROSS_COMPILE=../prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- ARCH=arm64 korlan-p2_defconfig CONFIG_DEBUG_SECTION_MISMATCH=y menuconfig

vim -d korlan-p2_defconfig .config
#根据 .config 去修改 korlan-p2_defconfig 即可

# 最后编译
```

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
最后将 defconfig 和 kernel 下的 defconfig 对比并修改
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
touch S90start_adb_udc.sh
vim S90start_adb.sh
chmod 777 S90start_adb.sh
```

然后在 S90start_adb.sh 中天添加需要执行的命令，比如

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

### S 开头文件从哪里来

在 package 有相同 S 开头的文件，并在 mk 文件中进行配置，比如：

```sh
a5_buildroot/buildroot$ find . -name "S80dnsmasq"
./package/dnsmasq/S80dnsmasq
a5_buildroot/buildroot$ grep -nr "S80dnsmasq" ./package/dnsmasq/
./package/dnsmasq/dnsmasq.mk:102:       $(INSTALL) -m 755 -D package/dnsmasq/S80dnsmasq \
./package/dnsmasq/dnsmasq.mk:103:               $(TARGET_DIR)/etc/init.d/S80dnsmasq
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

> **一般改了 deconfig 需要 make linux-dirclean ； make linux-rebuild 之后， `.config` 才会生效**

## buildroot 添加一个 config

以添加 timerstamp 为例

- 添加设备树

```c
//arch/arm64/boot/dts/amlogic/a5_a113x2_av400_1g_spk.dts
/ {
	timestamp {
		compatible = "amlogic, meson-soc-timestamp";
		reg = <0x0 0xFE0100EC 0x0 0x8>;
		status = "okay";
	};
}
```

- 修改 defconfig

```sh
# arch/arm64/configs/meson64_a64_smarthome_defconfig
CONFIG_AMLOGIC_SOC_TIMESTAMP=y
```

- 修改 Kconfig

```sh
# drivers/amlogic/Kconfig
CONFIG_AMLOGIC_SOC_TIMESTAMP=y

# drivers/amlogic/timestamp/Kconfig
# SPDX-License-Identifier: GPL-2.0-only
config AMLOGIC_SOC_TIMESTAMP
	bool "Amlogic SoC Timestamp"
	depends on ARCH_MESON || COMPILE_TEST
	depends on OF
	default y
	help
	  Say yes if you want to get soc-level timestamp.
```

- 修改 Makefile

```sh
# drivers/amlogic/Makefile
obj-$(CONFIG_AMLOGIC_SOC_TIMESTAMP)	+= timestamp/
```

- 添加 timerstamp 代码

drivers/amlogic/timestamp/


- 最后编译，编译的时候可能会出现是否选择开启 timerstamp ,输入 y 即可

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


## 内核 printk 文件

通过 `/proc/sys/kernel/printk` 文件可以调节 printk 的输出等级，该文件有 4 个数字值

```sh
$ cat /proc/sys/kernel/printk
4       4       1       7

# 关闭日志
echo 0 > /proc/sys/kernel/printk
```

四个数值的含义如下：

- 控制台日志级别：优先级高于该值的消息将被打印至控制台；
- 默认的消息日志级别：将用该优先级来打印没有优先级的消息；
- 最低的控制台日志级别：控制台日志级别可被设置的最小值（最高优先级）；
- 默认的控制台日志级别：控制台日志级别的缺省值。

这四个值是在 kernel/printk/printk.c 中被定义的，如下：

```c
int console_printk[4] = {
        CONSOLE_LOGLEVEL_DEFAULT,       /* console_loglevel */
        MESSAGE_LOGLEVEL_DEFAULT,       /* default_message_loglevel */
        CONSOLE_LOGLEVEL_MIN,           /* minimum_console_loglevel */
        CONSOLE_LOGLEVEL_DEFAULT,       /* default_console_loglevel */
};
EXPORT_SYMBOL_GPL(console_printk);
```

也可以调整默认的 log 打印级别

在 menuconfig 中修改

修改 CONFIG_MESSAGE_LOGLEVEL_DEFAULT 的值，然后重新编译，更新内核。menuconfig 配置路径如下：

```sh
Kernel hacking  --->
    printk and dmesg options  --->
        (4) Default message log level (1-7)
```

当 printk 中的消息日志级别小于当前控制台的日志级别（console_printk[0]）时，printk 的信息就会在控制台上显示。但无论当前控制台日志级别是何值，即使没有在控制台打印出来，都可以通过下面两种方法查看日志：

- 第一种是使用 dmesg 命令打印；
- 第二种是通过 cat /proc/kmsg 来打印。

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

## 获取分区的函数调用栈

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

# 设备驱动函数 platform_driver_probe 

在系统启动时自动探测和注册平台设备驱动程序。该函数是由 platform_driver_register 函数调用的，用于注册一个平台设备驱动程序并将其添加到内核的驱动程序列表中。

platform_driver_probe 函数的定义如下：


```c
int platform_driver_probe(struct platform_driver *drv, int (*probe)(struct platform_device *));
```

- drv 是一个指向 platform_driver 结构体的指针，该结构体包含了平台设备驱动程序的信息；
- probe 是一个指向函数的指针，该函数用于探测和初始化平台设备。

在系统启动时，内核会自动调用 platform_driver_probe 函数来探测和注册平台设备驱动程序。该函数会遍历系统中所有的平台设备，对于每个平台设备，会调用 probe 函数来探测和初始化设备。如果 probe 函数返回成功，则**该设备会被添加到内核的设备列表中**，以便其他驱动程序可以使用它。

# kernel 源码中一些函数介绍

## usb_add_phy_dev

`usb_add_phy_dev()` 函数可以用于将PHY设备与USB控制器相关联，从而使USB控制器能够正确地工作。

在Linux内核中，PHY 设备通常由 SOC（系统芯片）供应商提供，并且**负责完成USB信号的传输和调节**。在使用 USB 控制器之前，必须先为其分配一个 PHY 设备。usb_add_phy_dev() 函数可以用来完成这个操作。

此外，usb_add_phy_dev() 函数还有一个参数，即 USB 控制器对应的 platform_device 结构体指针。通过这个参数， usb_add_phy_dev() 函数可以将 PHY 设备和 USB 控制器绑定在一起，从而实现正确的数据传输和调节。

```c
// 函数原型
int usb_add_phy_dev(struct usb_phy *x)
```

## kstrtoint

kstrtoint 函数是一个C语言函数，通常用于将字符串转换为整数。它的原型如下：

```c
int kstrtoint(const char *s, unsigned int base, int *res);
```

其中，参数 s 是要转换的字符串；参数 base 是进制数，一般设置为 10 即可，表示十进制；参数 res 是转换后得到的整数。

该函数会尝试将字符串s解析成整数，并将结果存储在res中。如果转换成功，函数返回 0，否则会返回一个非零值，表示转换失败。需要注意的是，res必须指向已经分配了足够空间的内存，以存储转换后的整数。

以下是使用这个函数的伪代码

```c
static int __init my_init(void)
{
    char *str = "1234";
    int num;

    if (kstrtoint(str, 10, &num) != 0) {
        printk(KERN_ERR "Failed to convert string to integer\n");
        return -EINVAL;
    }

    printk(KERN_INFO "The converted integer is: %d\n", num);
    return 0;
}
```

## rmb wmb mb

**内存屏障**是一种硬件机制，用于保证内存操作的顺序和可见性。在多核系统中，不同 CPU 核心之间的内存访问可能存在乱序执行的情况，这会导致内存操作的顺序和可见性出现问题。内存屏障可以通过一些特殊的 CPU 指令来保证内存操作的顺序和可见性，从而避免这些问题。

`rmb()` 和 `wmb()` 分别表示读内存屏障和写内存屏障。它们的作用是：

- rmb()：确保在**读取某个内存位置之前**，先读取该位置之前的所有内存位置。这可以保证读取的数据是最新的，并且读取操作不会被重排到该位置之后。

- wmb()：确保在**写入某个内存位置之后**，先写入该位置之后的所有内存位置。这可以保证写入的数据对其他 CPU 核心可见，并且写入操作不会被重排到该位置之前。

在 Linux 内核中，rmb() 和 wmb() 函数通常用于同步不同 CPU 核心之间的内存访问，以确保内存操作的顺序和可见性。例如，在驱动程序中，当一个 CPU 核心修改了某个共享内存位置的值后，可以使用 wmb() 函数来确保该修改对其他 CPU 核心可见，从而避免出现数据不一致的情况。

- mb() 的作用是：
  - 确保在执行该函数之前的所有内存操作都已经完成。
  - 确保在执行该函数之后的所有内存操作都还没有开始。

`mb()` 函数通常用于同步不同 CPU 核心之间的内存访问，以确保内存操作的顺序和可见性。例如，在驱动程序中，当一个 CPU 核心修改了某个共享内存位置的值后，可以使用 `mb()` 函数来确保该修改对其他 CPU 核心可见，从而避免出现数据不一致的情况。


## configfs_write_file 

函数 configfs_write_file 是 Linux 内核中 configfs 文件系统的一个回调函数，它用于处理对 configfs 文件系统中某个文件的写操作。因此，当应用程序尝试向 configfs 文件系统中某个文件写入数据时，就会触发 configfs_write_file 函数的调用。

具体来说，当用户空间的应用程序通过系统调用 write() 向 configfs 文件系统中某个文件写入数据时，内核会将这个操作映射到 configfs 文件系统的相应 VFS inode 的 write() 方法上，而 configfs 文件系统又会将这个操作转发给对应 config_item 的 write_file 回调函数，最终调用 configfs_write_file 函数来完成实际的写操作。

```c
static ssize_t 
configfs_write_file(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
```

**对于 USB 驱动而言**，当用户空间中的应用程序通过 sysfs 接口向某个 USB 设备的配置文件写入数据时（例如 `/sys/bus/usb/devices/<bus>-<port>/<configuration>/bConfigurationValue` 文件）, 内核会将这个操作映射到 configfs 文件系统的相应 VFS inode 的 write() 方法上，而 configfs 文件系统又会将这个操作转发给对应 config_item 的 write_file 回调函数，最终调用 configfs_write_file 函数来完成实际的写操作。此时，USB 驱动可以在 configfs_write_file 函数中获取到用户空间写入的数据，并据此更新设备的配置描述符或属性。 也就是说在配置 USB 的时候会调用到这个函数。

需要注意的是，USB 设备通常有多个配置（configuration），每个配置包含多个接口（interface），每个接口包含多个端点（endpoint）。因此，在写入 USB 设备的配置文件时，需要同时指定配置、接口和端点等参数，才能精确地控制设备的行为。

## class_create

当一个新的设备驱动程序被加载到内核中时，通常会使用 class_create 来创建一个与其相关的设备类。

```c
acc_class = class_create(THIS_MODULE, "udc");

class_create --> __class_create --> __class_register

int __class_register(struct class *cls, struct lock_class_key *key)
{
	error = kobject_set_name(&cp->subsys.kobj, "%s", cls->name);
	error = class_add_groups(class_get(cls), cls->class_groups)
}
```

通过调用 class_create 函数，内核会在 `/sys/class` 目录下创建一个名为"`udc`"的子目录，该目录用于表示与这个设备类相关的设备。这个设备类可以被 USB gadget 驱动程序使用，以便为 USB 主机提供虚拟设备的支持。

-----

# 联合体寄存器位操作

```c
union usb_r5_v2 {
	/** raw register data */
	uint32_t d32;
	/** register bits */
	struct {
		unsigned iddig_sync:1;
		unsigned iddig_reg:1;
		unsigned iddig_cfg:2;
		unsigned iddig_en0:1;
		unsigned iddig_en1:1;
		unsigned iddig_curr:1;
		unsigned usb_iddig_irq:1;
		unsigned iddig_th:8;
		unsigned iddig_cnt:8;
		unsigned reserved:8;
	} b;
};
```

如果初始值： reg5.d32 = 0xfff3  1111111111110011

在进行 reg5.b.usb_iddig_irq = 0 操作后，第 7 位（从 0 开始）被清空，变成 0 ， 1111111101110011

所以 reg5.d32 = 0xff73

### 中断响应寄存器变化

```c
static irqreturn_t amlogic_crgotg_detect_irq(int irq, void *dev)
{
	union usb_r5_v2 reg5;
	reg5.d32 = readl((void __iomem *)((unsigned long)phy->phy3_cfg + 0x14));
	reg5.b.usb_iddig_irq = 0;
	schedule_delayed_work(&phy->work, msecs_to_jiffies(10));
}
```

上报一次中断，硬件会将 `reg5.b.usb_iddig_irq = 1`; 这个中断被响应处理了，就需要把中断位清楚，也就是 `reg5.b.usb_iddig_irq = 0`。


----


# USB 子系统

## USB子系统架构

USB 子系统架构两部分： **主机端** 和 **设备端**

![](http://mianbaoban-assets.oss-cn-shenzhen.aliyuncs.com/xinyu-images/MBXY-CR-6e2d183baf5c14ba85ab75176cb1793e.png)

![](https://zhuanlan.zhihu.com/p/558716468)

<strong><font color="orange" size=5>主机端</font></strong> 

主机端，简化成 三层

- 各种类设备驱动：uac, HID，CDC 等
- USB 设备驱动， USB core 处理
- 主机控制器驱动：不同的 USB 主机控制器不同（DHCI、EHCI、UHCI、XHCI）,统称 HCD

> **XHCI**（eXtensible Host Controller Interface）：XHCI 是一种 USB 控制器，它是 USB 3.0 和 USB 3.1 标准中使用的控制器。XHCI 控制器使用 DMA 技术来处理 USB 数据传输和控制，这使得 XHCI 控制器比 EHCI 控制器更快和更可靠。

<strong><font color="orange" size=5>设备端</font></strong> 

设备端，也抽象为三层：

- 设备功能驱动：mass sotage , CDC, HID 等，对应主机端的类设备驱动
- Gadget 设备驱动：中间层，向下直接和 UDC 通信，建立链接；向上提供通用接口，屏蔽USB请求以及传输细节。
- 设备控制器驱动（UDC）：UDC驱动，直接处理 USB 设备控制器。

参考： https://www.cnblogs.com/kn-zheng/p/17094595.html

https://zhuanlan.zhihu.com/p/558716468

### USB phy 架构关系

```
如果是 PC -- 开发板
                             +----------------+
                             |    USB Host    | PC 端
                             |   Controller   |
                             +----------------+
                                      | PC 传送数据
                                      |
                              +-------+-------+
                              |  USB Data Bus  | 数据总线
                              +-------+-------+
                                      |
                                      |
                            +---------+--------+
                            |     USB PHY      | 模拟信号 <==> 数字信号
                            +---------+--------+
                                      |
				      | USB Cable（USB线缆）是用于连接USB设备和USB主机之间
				      | 的一种特殊类型的数据传输线。它是一种数字信号传输线
				      |
         +--------------+--------------+---------------+
         |              |              |               |
    +----+----+    +----+----+    +-----+-----+    +----+----+
    | Device 1 |    | Device 2 |    |  Device 3 |    |  CPU   |
    |          |    | (Korlan) |    |           |    |        |
    +----------+    +----------+    +-----------+    +--------+
		IN Data Buffer    IN Data Buffer
		(Receive Buffer)  (Receive Buffer)
			|                 |
			|                 |
		+--------+--------+--------+-----------+
		|   SOC (System on Chip)               |
		|                                      |
		|            Out Data Buffer           |
		|            (Transmit Buffer)         |
		|                     |                |
		|             +-------+-------+        |
		|             |  USB Data Bus  |       |
		|             +-------+-------+        |
		|                     |                |
		+---------------------+----------------+
```

### USB  中的 ep

> **端点就是设备段存储数据的缓冲区**，存储已收到或者待发出的数据

在 USB 规范中，每个 USB 设备都有一个控制端点（Control Endpoint），也就是 EP0（Endpoint 0），它是 USB 设备配置和控制的主要通道。EP0 是在设备初始化时自动分配的，并且永远不会被请求配置为另一个类型的端点。

除了控制端点，USB 设备可以有多个数据端点（Data Endpoint）。这些数据端点用于传递输入和输出数据，以满足各种应用需求。常见的数据端点包括 EP1、EP2 等等。

EP1、EP2 等数据端点的具体功能取决于 USB 设备所实现的功能。例如，在音频设备中，EP1 可能用于接收麦克风输入数据，而 EP2 则用于发送扬声器输出数据。

需要注意的是，控制端点和数据端点最终都是由 USB 主机来控制访问的。主机通过发送控制命令和数据包到控制端点，然后通过数据端点进行数据传输。

### USB 的握手过程

USB 设备连接到主机时，它们需要进行握手以建立通信。USB 握手过程包括以下步骤：

- 设备上电和复位

当 USB 设备被插入主机时，设备会先接收到主机发送的 VBUS（+5V）信号，表示主机识别出了一个新的 USB 设备。然后，主机会向设备发送 RESET 信号，用于让设备进入默认状态。

- Speed request：主机会向设备发送一个速度请求，以确认双方通信速度是否一致。

- 设备地址分配

在设备被重置后，主机会向设备发送一个控制传输请求，用于分配设备地址。主机会指定一个唯一的地址，并将该地址发送给设备。设备会确认该地址，并开始使用该地址与主机通信。

- 配置描述符获取

一旦设备被赋予地址，主机就会开始请求设备的配置描述符。配置描述符是一个包含设备所需信息的数据结构，例如设备的速度、端点数量、端点类型等。设备会将配置描述符发送回主机。

- 配置确认

主机会验证设备的配置描述符，并根据需要选择一个合适的配置。一旦主机决定哪个配置最适合该设备，它会将该配置发送回设备进行确认。如果设备已准备好使用该配置，则会回复 ACK 响应。

- 界面和端点设置

一旦设备确认了配置，主机就会开始发送界面和端点设置请求。该请求用于配置设备的各个端点和界面，例如输入和输出端点、控制界面等。

- 握手完成

一旦设备完成了界面和端点的配置，它就准备好与主机进行通信了。此时，USB 握手过程就完成了，设备已经成功连接到主机，并可以开始进行数据传输了

## USB 获取 sof 数据包

要获取 USB SOF（Start of Frame）数据包，可以使用 Linux 内核中的 usbmon 工具。

确认 usbmon 是否已经加载
首先要确保 usbmon 已经在内核中加载并运行。可以通过以下命令查看：

ls /sys/kernel/debug/usb/usbmon/

如果输出结果类似于 0s  0t  1s  1t，则说明已经加载成功。

启动 usbmon 抓包

使用以下命令启动 usbmon：

```
sudo modprobe usbmon
sudo cat /sys/kernel/debug/usb/usbmon/<bus_number>t<device_address>
```

其中 `<bus_number>` 和 `<device_address>` 分别是设备所连接的总线编号和设备地址。例如，如果设备连接在总线 1，地址为 2，则应该输入以下命令：

sudo cat /sys/kernel/debug/usb/usbmon/1t2

这将在终端上打印出所有的 USB 数据包，其中包括 SOF 数据包。

过滤 SOF 数据包
如果只想查看 SOF 数据包，可以使用以下命令过滤：

```
sudo cat /sys/kernel/debug/usb/usbmon/<bus_number>t<device_address> | grep "SOF"
```

这将只显示包含 SOF 的数据包。

注意：usbmon 工具需要 root 权限才能使用。

## USB通讯过程

一次完整的通信分为三个过程：

- 请求过程（令牌包）
- 数据过程（数据包）
- 状态过程（握手包）

没有数据要传输时，跳过数据过程。

通信过程包含以下三种情况：

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.5rc2w8o9il40.webp)

主机发送令牌包（Token）开始请求过程，如果请求中声明有数据要传输则有数据过程，最后由数据接收方（有数据过程）或从机（无数据过程）发起状态过程，结束本次通信。

与 USB 全速设备通信时，主机将每秒等分为 1000 个帧（Frame）。主机在每帧开始时，向所有从机广播一个帧起始令牌包（Start Of Frame，SOF包）。它的作用有两个：
- 一是通知所有从机，主机的 USB 总线正常工作；
- 二是从机以此同步主机的时序。

与 USB 高速设备通信时，主机将帧进一步等分为 8 个微帧（Microframe），每个微帧占 125μ \muμs 。在同一帧内，8个微帧的帧号都等于当前SOF包的帧号。

------------

# 音频子系统

## UAC2


UVC（USB Audio Class）定义了使用USB协议播放或采集音频数据的设备应当遵循的规范。目前，UAC协议有UAC1.0和UAC2.0。UAC2.0协议相比UAC1.0协议，提供了更多的功能，支持更高的带宽，拥有更低的延迟。Linux内核中包含了 UAC1.0 和 UAC2.0 驱动，分别在 f_uac1.c 和 f_uac2.c 文件中实现。这里主要以 UAC2 驱动为例，具体分析 USB 设备驱动的初始化、描述符配置、数据传输过程等。 

### UAC2 源码分析

alloc_inst 被设置为 afunc_alloc_inst，alloc_func 被设置为 afunc_alloc，这两个函数在 Gadget Function API 层被回调。宏 DECLARE_USB_FUNCTION_INIT 将定义一个 usb_function_driver 数据结构，使用 usb_function_register 函数注册到 function API 层。

```c
//drivers/usb/gadget/function/f_uac2.c

DECLARE_USB_FUNCTION_INIT(uac2, afunc_alloc_inst, afunc_alloc); 
```

先来看看 f_uac2 结构体, 由 afunc_alloc 分配，包含具体音频设备和 USB 配置信息。

```c
struct f_uac2 {
	struct g_audio g_audio;
	u8 ac_intf, as_in_intf, as_out_intf;
// - ac_intf - audio control interface，接口描述符编号为0
// - as_in_intf - audio streaming in interface，接口描述符编号为2
// - as_out_intf - audio streaming out interface，接口描述符编号为1

	u8 ac_alt, as_in_alt, as_out_alt;	/* needed for get_alt() */
};


//g_audio 表示音频设备，包含了音频运行时参数、声卡、PCM设备等信息
struct g_audio {
	struct usb_function func;  // 描述了USB设备功能的回调函数
	struct usb_gadget *gadget;

	struct usb_ep *in_ep;   //输入端点
	struct usb_ep *out_ep;  // 输出端点

	/* Max packet size for all in_ep possible speeds */
	unsigned int in_ep_maxpsize;  // 输入端点数据包最大长度
	/* Max packet size for all out_ep possible speeds */
	unsigned int out_ep_maxpsize;  // 输出端点数据包最大长度

	/* The ALSA Sound Card it represents on the USB-Client side */
	struct snd_uac_chip *uac;

	struct uac_params params;  // 音频参数
};
```

#### afunc_alloc_inst

- afunc_alloc_inst 里面主要是分配一个 usb_function_instance （音频数据） 实例结构体，并赋值一些默认参数。**这里注意两个参数 p_chmask 和 c_chmask** ，如果你从事的是 linux 内核相关的工作，声音播放一段时间后出现 underrun 问题（kernel log), 或者 overrun (应用 log) 问题，可以检查一下这两个参数是否设置正确。

- 另外还有这个函数：afunc_free_inst ，这个函数就不用说了吧，看看函数名字再对比下 afunc_alloc_inst 这个函数名字，很明显是一个分配一个释放嘛，走进函数内部一看，发现就只有一行核心代码：`opts = container_of(f, struct f_uac2_opts, func_inst);`  。


```c
static struct usb_function_instance *afunc_alloc_inst(void)                                                                                                                                                      
{
		struct f_uac2_opts *opts;  //ops保存音频属性参数信息

		opts = kzalloc(sizeof(*opts), GFP_KERNEL);
		if (!opts)
				return ERR_PTR(-ENOMEM);

		mutex_init(&opts->lock);
		
		opts->func_inst.free_func_inst = afunc_free_inst;

		//这里是用来给用户空间操作的节点
		//https://blog.csdn.net/u011037593/article/details/123698241?spm=1001.2014.3001.5501
		config_group_init_type_name(&opts->func_inst.group, "",
									&f_uac2_func_type);

		//默认参数在 u_uac2.h 中设置
		opts->p_chmask = UAC2_DEF_PCHMASK;  //0x3  默认录音是双声道
		opts->p_srate = UAC2_DEF_PSRATE;    //48000
		opts->p_ssize = UAC2_DEF_PSSIZE;	//2
		opts->c_chmask = UAC2_DEF_CCHMASK;	//0x3  默认播放是双声道
		opts->c_srate = UAC2_DEF_CSRATE;	//64000  默认播放采样率是 64000， 一般都会改成 48000
		opts->c_ssize = UAC2_DEF_CSSIZE;	//2  一般都会改成 4
		opts->req_number = UAC2_DEF_REQ_NUM;  //2
		return &opts->func_inst;
}
```

- f_uac2_opts 这个数据结构定义了音频数据的一些属性参数

```c
struct f_uac2_opts {
	struct usb_function_instance	func_inst;  // 功能回调函数
	int				p_chmask;  // 录音通道掩码
	int				p_srate;   // 录音采样率
	int				p_ssize;   // 录音一帧数据占多少字节
	int				c_chmask;  // 播放通道掩码
	int				c_srate;   // 播放采样率
	int				c_ssize;   // 播放一帧数据占多少字节
	int				req_number;  // usb_request的数量
	bool			bound;
	struct mutex	lock;
	int				refcnt;  // 引用计数
};	
```

#### afunc_alloc

afunc_alloc 其主要功能是为音频设备分配一个新的音频功能结构体，并将其初始化。音频功能结构体是音频驱动中的一个重要数据结构，用于描述音频设备的各种功能和属性，例如音量控制、混音、采样率等。

在初始化音频功能结构体之后，afunc_alloc 函数会将其添加到音频设备的功能列表中，以便其他函数可以使用它。同时，它还会返回指向音频功能结构体的指针，以便其他函数可以直接访问它。

```c
static struct usb_function *afunc_alloc(struct usb_function_instance *fi)
{
	struct f_uac2	*uac2;
	struct f_uac2_opts *opts;

	uac2 = kzalloc(sizeof(*uac2), GFP_KERNEL);
	if (uac2 == NULL)
		return ERR_PTR(-ENOMEM);

	opts = container_of(fi, struct f_uac2_opts, func_inst);
	mutex_lock(&opts->lock);
	++opts->refcnt;
	mutex_unlock(&opts->lock);

	uac2->g_audio.func.name = "uac2_func";  // //这里是function的名字
	uac2->g_audio.func.bind = afunc_bind;	// //用来绑定设备和 function 的函数
	uac2->g_audio.func.unbind = afunc_unbind;
	uac2->g_audio.func.set_alt = afunc_set_alt;  // composite_setup 这里调用
	uac2->g_audio.func.get_alt = afunc_get_alt;
	uac2->g_audio.func.disable = afunc_disable;
	uac2->g_audio.func.setup = afunc_setup;
	uac2->g_audio.func.free_func = afunc_free;

	//control_selector_init(uac2);  可以通过这个函数添加扩展的控制器

	return &uac2->g_audio.func;
}
```

- name 属性是一个字符串，用于标识这个音频功能结构体；
- afunc_bind 和 afunc_unbind 是回调函数，用于在音频设备与主机之间建立和断开连接时执行相应的操作；
  - 在执行afunc_bind函数时，它会首先检查音频设备是否已经被初始化，如果没有，则会调用相应的初始化函数来初始化音频设备。然后，它会设置音频设备的各种属性和参数，例如采样率、通道数、音量等。接下来，它会启动音频传输，**并开始接收和发送音频数据 （ `g_audio_setup` : 启动音频传输 ，另外该函数中还会注册中断处理程序，以便在音频数据传输期间处理中断）**。

- afunc_set_alt 和 afunc_get_alt 是回调函数，用于设置和获取音频设备的备用接口（alternate interface）；
- afunc_disable 用于禁用音频设备；
- afunc_setup 用于在音频设备初始化时执行一些特定的操作；
- afunc_free 用于释放音频功能结构体的内存空间。


### uac2 驱动通过 configfs 的配置

> 参考来源： https://blog.csdn.net/u011037593/article/details/121458492

uac2驱动通过configfs的配置过程如下图所示，创建functions调用uac2驱动的afunc_alloc_inst函数，关联functions和配置时调用uac2驱动的afunc_alloc，使能gadget设备调用uac2驱动的afunc_bind函数，下面分析这三个函数的执行过程。

![](https://img-blog.csdnimg.cn/bbe66e10d68a4c2dae940fb97b77b546.png#pic_center)

USB 设备的枚举实质上是响应 USB 主机发送请求的过程。对于一些标准的 USB 请求，如 USB_REQ_GET_STATUS、USB_REQ_CLEAR_FEATURE 等，USB 设备控制器驱动就可以处理，但有一些标准的USB请求，如 USB_REQ_GET_DESCRIPTOR，需要 USB gadget 驱动参与处理，还有一些 USB 请求，需要 function 驱动参与处理。如下图所示，当主机发送 USB_REQ_GET_CONFIGURATION 或 USB_REQ_SET_INTERFACE 请求时，需要调用 uac2 驱动的 afunc_set_alt 函数处理，当主机发送 USB_REQ_GET_INTERFACE 请求时，需要调用 afunc_get_alt 函数处理，其他USB类请求命令，调用 afunc_setup 处理。

![](https://img-blog.csdnimg.cn/5f5a6db95d1b4a4b9640be663fdd3f2b.png#pic_center)

> **UAC2设备被枚举的过程如下（这里只说明uac2驱动参与处理的部分）：**

- 设置配置

主机发送 USB_REQ_GET_CONFIGURATION 命令设置设备当前使用的配置。uac2 驱动只有一个配置，因此只需要调用 afunc_set_alt 将配置下面所有接口的 alt 值设置为 0。afunc_set_alt 函数的执行流程如下图所示。若是音频控制接口，alt=0 时，直接返回 0，其他值直接报错；若是音频流**输出接口**，alt=0 时，停止录音，alt=1 时，开始录音；若是音频流**输入接口**，alt=0 时，停止播放，alt=1 时，开始播放。

![](https://img-blog.csdnimg.cn/b64cc232240346e28a876f8ec606bb15.png#pic_center)

### uac2 工作过程分析

USB主机发送 USB_REQ_SET_INTERFACE 命令时，uac2 驱动将会调用 afunc_set_alt 函数，若 intf=2，alt=1 ，则开始录音，若 intf=1，alt=1，则开始播放。下图是 USB 音频设备工作时数据流的传输过程。录音（capture）时，USB 主机控制器 (PC) 向 USB 设备控制器 (板子 SOC) 发送音频数据，USB 设备控制器收到以后通过 **【DMA控制器】** 将其写入到 usb_request 的缓冲区中，随后再拷贝到 DMA 缓冲区中，**用户可使用 arecord、tinycap 等工具从 DMA 缓冲区中读取音频数据**，DMA 缓冲区是一个 FIFO ，uac2 驱动往里面填充数据，用户应用程序从里面读取数据。播放（playback）时，用户通过 aplay、tinyplay 等工具将音频数据写道 DMA 缓冲区中，uac2 驱动从 DMA 缓冲区中读取数据，然后**构造成 usb_request** ，送到 USB 设备控制器，USB 设备控制器再将音频数据发送到 USB 主机控制器。可以看出录音和播放的音频数据流方向相反，用户和 uac2 驱动构造了一个生产者和消费者模型，录音时，uac2 驱动是生产者，用户是消费者，播放时则相反。

- Capture : PC  --> SOC
- Playback: SOC --> PC

![](https://img-blog.csdnimg.cn/378f49e244a94f558fb17b3d5f2be987.png#pic_center)
> 图片来源：https://blog.csdn.net/u011037593/article/details/121458492

> **如果使用 tdm_bridge**

- Capture : PC --> USB 控制器 --> usb_request (USB请求包) --> complete --> tdm_bridge 写到 DAM buf --> tdm --> speaker

- Loopback: PC --> USB 控制器 --> usb_request (USB请求包) --> complete --> tdm_bridge 写到 DAM buf --> tdm_bridge 读 DAM buf --> 形成 usb_request --> USB 控制器

## Linux ALSA音频系统架构

### ALSA 声卡驱动

ALSA是 Advanced Linux Sound Architecture 的缩写，目前已经成为了linux的主流音频体系结构，想了解更多的关于ALSA的这一开源项目的信息和知识，请查看以下网址：http://www.alsa-project.org/。

在内核设备驱动层，ALSA提供了 alsa-driver，同时在应用层，ALSA 为我们提供了 alsa-lib，应用程序只要调用 alsa-lib 提供的 API，就可以完成对底层音频硬件的控制。

用户空间的 alsa-lib 对应用程序提供统一的API接口，这样可以隐藏了驱动层的实现细节，简化了应用程序的实现难度。

内核空间中，alsa-soc (ASOC) 其实是对 alsa-driver 的进一步封装，他针对嵌入式设备提供了一些列增强的功能

- `kernel/sound/core` 该目录包含了ALSA驱动的中间层，它是整个 ALSA 驱动的核心部分。

- `kernel/sound/soc` 针对 system-on-chip 体系的中间层代码

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/alsa架构.3jj3illr82y0.webp)

- **Alsa application**: aplay, arecord, amixer, 是 alsa alsa-tools 中提供的上层调试工具，用户可以直接将其移植到自己所需要的平台，这些应用可以用来实现 playback, capture, controls 等。
- **alsa library API**: alsa 用户库接口，常见有 alsa-lib. ( alsa-tools 中的应用程序基于 alsa-lib 提供的 api 来实现)
- **ALSA core**: alsa　核心层，向上提供逻辑设备(`pcm/ctl/midi/timer/..`)系统调用，向下驱动硬件设备(`Machine/i2s/dma/codec`)
- **ASsoc core**:asoc是建立在标准alsa core基础上，为了更好支持嵌入式系统和应用于移动设备的音频codec的一套软件体系。
- **hardware driver**: 音频硬件设备驱动，由三大部分组成，分别是 machine, platform, codec .

### ASOC架构

**ASoC 把音频系统同样分为3大部分：Machine，Platform 和 Codec**

在 ASoC 驱动框架中 cpu 部分称作 platform，声卡部分被称作 codec，两者通过 machine 进行匹配连接；machine 可以理解为对开发板的抽象，开发板可能包括多个声卡.

- <strong><font color="orange" size=4>platform：</font></strong> **platform+cpu_dai**  

Platform  一般是指某一个SoC平台，比如 MT6582, MT6595, Amlogic-AV400 等等，与音频相关的通常包含该 SoC 中的 Clock、FAE、I2S、DMA 等等,该模块负责 DMA 的控制和 I2S 的控制, 由 CPU 厂商负责编写此部分代码。

>- 录音数据通路：麦克风 ----> 声卡 –-(I2S) --> DMA ---->内存；
>- 播放数据通路：内存 ----> DMA –-(I2S) --> 声卡 ---->扬声器；

> DAM 控制器： 负责内存和外设之间的数据传递，不需要经过 CPU


- <strong><font color="orange" size=4>Codec:</font></strong>  **codec+codec_dai**

Codec 是音频编解码器，它负责将模拟音频信号转换为数字音频信号，或者将数字音频信号转换为模拟音频信号。Codec 通常由硬件实现，它可以支持多种不同的音频编解码格式，例如 PCM、MP3、AAC 等。

Codec DAI 是连接音频 CODEC 和其他音频组件的接口，它负责将音频数据从 CODEC 发送到其他组件，或者从其他组件接收音频数据并传输到 CODEC。Codec DAI 通常由 CODEC 驱动程序实现，它可以支持多种不同的音频接口，例如 I2S、PCM、AC97 等。

- <strong><font color="orange" size=4>Machine</font></strong>

Machine 是指某一款机器，可以是某款设备，某款开发板，又或者是某款智能手机，由此可以看出Machine几乎是不可重用的，每个 Machine 上的硬件实现可能都不一样，CPU 不一样，Codec不一样，音频的输入、输出设备也不一样，Machine为CPU、Codec、输入输出设备提供了一个载体 ，用于描述一块电路板, 它指明此块电路板上用的是哪个Platform和哪个Codec, 由电路板商负责编写此部分代码。 绑定 platform driver 和 codec driver


![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/asoc架构图.561ca6zjfm80.webp)

**参考**：
- 对 alsa 数据结构，函数源码进行介绍： https://www.linuxidc.com/Linux/2019-01/156223.htm
- 对 Asoc 详细介绍： https://www.cnblogs.com/blogs-of-lxl/p/6538769.html
- UAC 麦克风学习： https://www.usbzh.com/article/detail-505.html
- 实现自己的 alsa 驱动： https://blog.csdn.net/u014056414/article/details/120988882

## 音频传输计算

> **对于单声道，采样率为 48000 , 1ms 能读取多少数据？**

如果每个采样点需要占用 32 位（4 个字节），则每毫秒需要读取的字节数为 192。

因此，在单声道、采样率为 48000、每个采样点占用 32 位的情况下，每毫秒能够读取 48 个采样点，即 192 字节的数据。

