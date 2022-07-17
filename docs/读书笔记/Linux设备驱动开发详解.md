
----

# 第三章 Linux内核及编程

## Linux内核的编译

```sh
#make config（基于文本的最为传统的配置界面，不推荐使用）
#make menuconfig（基于文本菜单的配置界面)
```

内核配置包含的条目相当多，`arch/arm/configs/xxx_defconfig`文件包含了许多电路板的默认配置。只需要运行 `make ARCH=arm xxx_defconfig` 就可以为 xxx 开发板配置内核。

```sh
linux-5.6.14/arch/arm/configs
```

编译模块和方法是

```sh
make ARCH=arm zImage
make ARCH=arm modules
```

执行完上述命令后，在源代码的根目录下会得到未压缩的内核映像 vmlinux 和内核符号表文件 System.map，在 arch/arm/boot/ 目录下会得到压缩的内核映像 zImage，在内核各对应目录内得到选中的内核模块。

使用 make config 或者 make menuconfig 命令后，会生成一个 .config 配置文件，记录哪些被编译进内核，哪些被编译进内核模块。

其过程是：

- 配置工具先分析与体系结构对应 ach/xxx/Kconfig 文件（xxx就是 ARCH 的参数，比如 arm），arch/xxx/Kconfig 文件中会引入一系列的 Kconfig 配置文件，这些 Kconfig 可能是下一层的 Kconfig。

在 drivers/char 目录中包含了 TTY_PRINTK 设备驱动的源代码 drivers/char/ttyprintk.c。而在该目录的 Kconfig 文件中包含关于 TTY_PRINTK 的配置项：

```mk
config TTY_PRINTK
    tristate "TTY driver to output user messages via printk"
    depends on EXPERT && TTY 
    default n
    ---help---
      If you say Y here, the support for writing user messages (i.e.
      console messages) via printk is available.

      The feature is useful to inline user messages with kernel
      messages.
      In order to use this feature, you should output user messages
      to /dev/ttyprintk or redirect console to this TTY.

      If unsure, say N.
```

上述 Kconfig 文件的这段脚本意味着只有在 EXPERT 和 TTY 被配置的情况下，才会出现 TTY_PRINTK 配置项.

选“Y”时会直接将生成的目标代码连接到内核，选“M”时则会生成模块 ttyprintk.ko；如果TTY_PRINTK配置选项被选择为“N”，这不编译。


驱动开发者会在内核源代码的 drivers 目录内的相应子目录中增加新设备驱动的源代码或者在 arch/arm/mach-xxx 下新增加板级支持的代码，同时增加或修改Kconfig配置脚本和Makefile脚本

### Kconfig

例子

```c
config EXT3_FS_SECURITY
	bool "Ext3 Security Labels"   //类型
	depends on EXT3_FS            //依赖属性
	select EXT4_FS_SECURITY       //选择属性
	help                          //帮助属性
	  This config option is here only for backward compatibility. ext3
```

#### 配置选项

- 大多数内核配置选项都对应 Kconfig 中一个 config，config 之后接的是配置选项的属性，每个配置选项都必须指定类型，，包括：类型（类型包括 bool、tristate、string、hex和 int。），数据范围，输入提示，依赖关系，选择关系，帮助信息，默认值。

```c
bool “Networking support”

等价于
bool
prompt "Networking support"
```

- 输入提示的一般格式为,其中，可选的 if 用来表示该提示的依赖关系

```c
prompt <prompt> [if <expr>]
```

- 依赖关系的格式为

```c
depends on（或者requires） <expr>
```

- 默认值的格式为,如果用户不设置对应的选项，配置选项的值就是默认值

```c
default <expr> [if <expr>]
```

- 如果定义了多重依赖关系，它们之间用 “&&” 间隔。

依赖关系也可以应用到该菜单中所有的其他选项（同样接受if表达式）内，下面两段脚本是等价的：

```c
bool "foo" if BAR
default y if BAR

// 等价

depends on BAR
bool "foo"
default y
```

- 选择关系（也称为反向依赖关系）的格式如下，A 如果选择了B，则在A被选中的情况下，B自动被选中

```c
select <symbol> [if <expr>]    
```

- 数据范围的格式如下，

```c
range <symbol> <symbol> [if <expr>]
```

- Kconfig中的expr（表达式）定义

```c
<expr> ::= <symbol>
    <symbol> '=' <symbol>
    <symbol> '!=' <symbol>
    '(' <expr> ')'
    '!' <expr>
    <expr> '&&' <expr>
    <expr> '||' <expr>
```

