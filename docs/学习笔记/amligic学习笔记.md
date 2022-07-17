


------

## 进入make gui 界面

make ARCH=arm menuconfig

`arch/arm/configs/xxx_defconfig`文件包含了许多电路板的默认配置。只需要运行 `make ARCH=arm xxx_defconfig` 就可以为 xxx 开发板配置内核。


编译内核和模块的方法是

···
make ARCH=arm zImage
make ARCH=arm modules
···

上述命令中，如果A RCH=arm 已经作为环境变量导出，则不再需要在 make 命令后书写该选项。执行完上述命令后，在源代码的根目录下会得到未压缩的内核映像 vmlinux 和内核符号表文件 System.map，在 `arch/arm/boot/` 目录下会得到压缩的内核映像 zImage，在内核各对应目录内得到选中的内核模块。

Linux内核的配置系统由以下3个部分组成

- Makefile：分布在Linux内核源代码中，定义Linux内核的编译规则
- 配置文件（Kconfig）：给用户提供配置选择的功能
- 配置工具：包括配置命令解释器（对配置脚本中使用的配置命令进行解释）和配置用户界面（提供字符界面和图形界面）。这些配置工具使用的都是脚本语言，如用 Tcl/TK、Perl 等

> 使用 make config、make menuconfig 等命令后，会生成一个 `.config` 配置文件，记录哪些部分被编译入内核、哪些部分被编译为内核模块

