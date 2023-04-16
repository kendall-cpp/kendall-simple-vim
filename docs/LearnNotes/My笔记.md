# linux 源码学习笔记

# **USB 笔记**

## 什么是端点

所有的总线传输要么是传到设备端点 (device endpoint)，要么是从设备端点传送过来。端点其实就是**多个数据直接的缓冲区** ， 所以端点中存的数据是**待发送的**数据或者是**待接收的**数据，

另外主机没有端点，但是同样有缓冲区，

端点的地址由【端点号 (0-15)】和【方向 (in / out)】组成，

device --in--> 主机 --out--> device 

每个设备都必须要有 1 个控制端点【端点 0】 。控制端点包含着一对 IN 和 OUT 端点地址。

除了端点 0 外， 全速 和 高速 设备可拥有多达 30 个额外端点地址（1-15的 IN 和 OUT），低速设备最多有两个端点地址，可以是两个 IN 、两个 OUT 或者两个方向各一个。

## USB 传输类型

我们知道，传输事务解决了主机、设备之间交互一次数据的问题，但是有些端点是需要进行多次双向传输或者多次单向传输的，同时因为设备的功能不同，所需要的带宽和传输特性也不同，那么就需要一个更上层的机制解决以上问题，也就是 USB 的四大传输。

控制传输（Control Transfers）、中断传输（Interrupt Transfers）、批量传输（Bulk Transfers）、同步传输（Isochronous Transfers）称之为四大传输。

 控制传输

**一种可靠的双向传输**。 控制传输分为 初始设置阶段--->数据阶段(不必须)--->状态信息 阶段，每个阶段都是由一个或者多个事物组成，每个控制传输必须包含有**设置和状态**阶段，不是所有的传输都有数据阶段。

该传输一般发生在端点 0 中，用于USB的枚举、配置（也可能进行其他数据传输）等阶段。

当设备插入主机后，主机通过端点 0 进行控制传输，通过一系列的数据交互，主机就可以知道连接的设备有多少个接口，有多少个可用的端点等设备信息。


 设置阶段

主机发送请求信息，开始设置事务。令牌信息包的 SETUP 包标识符 将事务 确定为可以开始控制传输的【设置事务】。

 批量传输

中断传输

等时传输

---

## USB协议文档

### Universal Serial Bus Specification

USB 协议规范

（通用串行总线规范）是由USB Implementers Forum（USB-IF）制定和发布的一系列关于USB协议标准的文件。该规范详细介绍了USB协议的各个方面，包括物理层、数据链路层、传输层、设备和主机通信等各个方面。

该规范的版本包括USB 1.x、USB 2.0、USB 3.x和USB Type-C等，每个版本都有对应的规范文件。其中，USB 1.x规范包括USB 1.0、USB 1.1和USB 2.0低速（1.5 Mbps）和全速（12 Mbps）规范，USB 2.0规范则增加了高速（480 Mbps）规范，USB 3.x则增加了超高速（5 Gbps、10 Gbps）规范，而USB Type-C规范则对连接器和电源传输进行了扩充。

USB规范涵盖了USB协议栈的每个层次的内容，使厂商能够实现兼容的USB设备、主机和相关系统。同时该规范是为确保全球各地的USB设备能够相互兼容的必要手段，USB-IF官方认证标志和兼容性测试也建立于此规范基础上。


### USB Complete: The Developer's Guide

是由Jan Axelson所著的一本关于USB开发的指南书籍，它详细介绍了USB技术的原理、协议及其实现。该书可以帮助读者了解USB技术的基本概念和原理，并且提供了大量的实际案例和示例代码，使得读者能够更好地理解USB开发的技术细节。

该书共有26章，内容包括了从USB 1.x到USB 3.x、USB Type-C的各个版本协议的细节和特点，涉及到USB传输、设备和主机通信、USB的电源管理、HID设备和UVC摄像头等。除此之外，该书还介绍了USB的硬件设计、PCB设计、阻抗匹配、背板的设计等，并提供了一些开发工具和测试工具的推荐。

该书的读者面向USB开发工程师、硬件工程师、软件工程师以及对USB技术感兴趣的专业人士。读者可以根据自己的工作需要选择相关章节进行阅读，也可以作为USB开发的入门手册。


USB-IF官网地址为 https://www.usb.org ，您可以在该网站上注册成为会员并下载最新的USB规范和技术文档。

以下是一些常用的USB规范文档和技术文档的下载地址：

USB 2.0规范文档：https://www.usb.org/document-library/usb-20-specification
USB 3.2规范文档：https://www.usb.org/document-library/usb-32-specification-released-july-26-2019
USB Type-C规范文档：https://www.usb.org/document-library/usb-type-ctm-specification-revision-21
HID规范文档：https://www.usb.org/document-library/hid-111-spec-and-descriptors
UVC规范文档：https://www.usb.org/document-library/usb-video-class-specification-revision-20
以上地址仅供参考，如有变动或更新，请以USB-I

## USB 控制器

## crg 控制器和 dwc 控制器

CRG控制器和DWC控制器是常见的USB控制器，它们在USB设备中扮演着非常重要的角色。

CRG控制器（Clock and Reset Generator）是芯片中负责时钟和复位信号的发生和控制的模块，它可以控制内部时钟的频率、相位和稳定性，保证USB数据传输的精度和可靠性。 CRG控制器通常被用于控制USB PHY、USB OTG、UART、I2C等接口的时钟和复位功能。CRG控制器能够提供时钟生成器、PLL锁相环、时钟分频器、复位发生器等功能，可以满足系统中不同模块的时钟和复位信号需求。

DWC控制器（DesignWare® USB IP）是一组开源硬件IP，能够实现USB 2.0和USB 3.0的Host和Device功能；DWC控制器广泛应用于各种芯片，并得到了良好的市场口碑。DWC控制器能够提供高性能、低延迟的数据传输，并针对性能、功耗和面积等方面的要求，在内部集成了高度可定制和可配置的功能单元。DWC控制器能够支持不同的USB Phy和常见的USB应用层协议，例如Mass Storage、Audio、Human Interface Device（HID）等，适用于多种应用场景。

总的来说，CRG控制器是用于控制USB设备内部时钟和复位信号的模块，而DWC控制器是用于实现USB通信协议和数据传输的标准IP。这两种控制器在USB设备的设计和开发中扮演着非常重要的角色。

### USB驱动程序、USB控制器、USB DEVICE等的功能和相互作用方式

- USB控制器


USB控制器位于主板芯片组中，主要负责控制USB总线上所有的USB设备。USB控制器包括两个主要模块：

（1）主机控制器

主机控制器位于主机设备或USB主机控制器中。主机控制器负责与USB总线上的所有设备通信，包括识别和配置新的设备，带宽分配和电源管理等任务。

主机控制器还负责处理USB数据包，并将数据包从USB总线中接收或发送到USB设备。因此，在任何一个USB主机控制器上都会有一个或多个主机控制器，它们负责控制USB总线上的数据传输和管理。

（2）设备控制器

USB设备是指连接到USB总线上的任何外部设备。 USB设备需要遵循USB协议和设备通信规范，这将确保USB设备与其他类型的设备能够兼容和互相操作。

USB设备之间的通信主要依靠USB设备描述符，每个USB设备描述符有一个唯一的地址和类型，用于识别或通信到该设备。

每个USB设备通常包括一个或多个功能接口，这些功能接口为主机控制器提供了各种服务，例如打印、扫描、存储等。

- USB设备


USB设备是指USB总线上连接的外部设备，例如鼠标、键盘、打印机和手机等。每个USB设备通常包括一个设备控制器和一个或多个功能接口，它们向主机控制器提供各种服务。

USB设备需要支持标准的USB协议和通信协议，以确保与主机控制器和其他设备之间的兼容性和互操作性。

- USB驱动程序


USB驱动程序是一种接口软件，允许USB设备与操作系统通信。USB驱动程序通常包括硬件抽象层和驱动程序代码。

USB驱动程序负责：

（1）在USB设备上安装和卸载设备驱动程序。
（2）实现USB设备的基本功能。
（3）管理USB设备的电源和带宽使用情况。
（4）发送和接收数据包。

### USB phy

PHY（Physical Layer，物理层）是 USB 系统中的一个组成部分，它实现了 USB 总线物理层的功能，负责收发 USB 数据包和控制信号。因此，PHY 中包含了 USB 信号的收发电路和控制电路等。

USB PHY的作用是将高层协议（例如USB设备和主机的通信）、传输数据和电缆之间的物理网络层之间进行转换。它实现了USB总线的电气和物理规范。PHY 主要负责三个方面的功能：

（1）时序控制：确保数据和控制信号在正确定时发送和接收，这包括时钟频率的控制和延迟的补偿等。

（2）传输编码：转换 USB 数据并将其编码为数据传输模式，使它符合 USB 的标准传输协议。

（3）信号驱动：把转换后的数字信号驱动到 USB 总线中以进行数据传输。

需要注意的是，USB PHY 通常与芯片本身整合在一起，但是 USB PHY 并不是 USB 芯片本身的一部分，因为它可以由其他芯片提供支持。在实践中，USB PHY 的实现经常随着制造工艺和应用环境的变化而出现不同的工程挑战，因此，它的性能和设计需要根据具体情况进行优化和调整。


# 今年的任务

- 零声学院+博客网址，需要认真看完： http://www.wowotech.net/sort/memory_management

- PCM EQ DRC 音频处理： https://www.cnblogs.com/yuanqiangfei/p/9896855.html

- 音效只是了解： https://blog.csdn.net/u011764302/article/details/122236564

- 学习音频子系统： lsken00 书签

- 《USB开发大全》

- 看哈工大的计算机组成原理课程，学习计算机组成原理，芯片一些知识，记笔记
  - 《计算机组成与设计：硬件 / 软件接口》
  - 深入理解计算机系统

- 研究C语言
  - 《C 陷阱与缺陷》
  - 《C 编程专家》

- 《设备驱动程序》 这本书也是必看

----

# **安装和编译自己的内核**

> **ARM64 版本**

参考网址：https://www.jianshu.com/p/a0d166bfe21f

## 安装相关支持库

```sh
apt-get install libpixman-1-dev
 
sudo apt-get install zlib1g-dev
sudo apt-get install libglib2.0-0
sudo apt-get install libglib2.0-dev
```

## 安装qemu 

从qemu官网下载源码文件 qemu-6.2.0.tar.xz

```sh
tar -xvf qemu-6.2.0.tar.xz

# 编 译
export PATH="/home/book/kenspace/linux-kernel/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin:${PATH}"
./configure --prefix=/home/book/kenspace/linux-kernel/qemu   # 指定需要安装的路径

./configure --target-list=x86_64-softmmu,x86_64-linux-user,arm-softmmu,arm-linux-user,aarch64-softmmu,aarch64-linux-user --enable-kvm --prefix=/home/book/kenspace/linux-kernel/qemu  
```

如果出现编译错误，参考这里解决。 https://blog.csdn.net/birencs/article/details/126666827


make 

最后将 `/home/book/kenspace/linux-kernel/qemu/bin` 添加到环境变量中

qemu安装完成。

## 安装交叉编译器

```
sudo apt-get install gcc-arm-linux-gnueabi
```

## 配置脚本目录

参考我的目录关系

```sh
book@kendall:~/kenspace/linux-kernel$ ls
buildroot-2022.02  build-vexpressa9  qemu  buildroot-dl

book@kendall:~/kenspace/linux-kernel/build-vexpressa9$ ls
build.sh    output-vexpress-v2p-ca9 
```

cd build-vexpressa9

在该目录下建立编译建立 build.sh ，输入如下内容

```sh
#! /bin/bash

TPWD=$(pwd)
echo $TPWD
cd $TPWD/../buildroot-2022.02/
#mkdir -p $TPWD/output-vexpress-v2p-ca9
make O=$TPWD/output-vexpress-v2p-ca9 ARCH=arm $1
```

## 配置 buildroot

> 我这里使用的 buildroot 版本是 buildroot-2022.02

- make defconfig

这里的 defconfig 是根据不同型号的板子自行确定的，对应于 buildroot/configs 目录下的配置文件，我们这里仿真的是vexpress，qemu_arm_vexpress_defconfig 。

- 配置

```sh
cd build-vexpressa9/
./build.sh qemu_arm_vexpress_defconfig
```

可以看到 build-vexpressa9/output-vexpress-v2p-ca9 文件夹下生成了 .config 文件

注意： 这一步之后就不要再 ./build.sh qemu_arm_vexpress_defconfig 了，否则会重新初始化 .config 

- 配置 buildroot 相关参数

安装 menuconfig 的依赖库文件

```sh
sudo apt-get install build-essential 
sudo apt-get install libncurses5 
sudo apt-get install libncurses5-dev 
```

```sh
cd build-vexpressa9/
./build.sh menuconfig
```

- Target options主要是和架构有关的配置，一般我们使用ARCH=arm或者其他架构后，一般不需要做调整

- Build options主要是设置和buildroot相关的参数，比如说下载目录、主机环境的配置地址等等

```sh
/home/book/kenspace/linux-kernel/buildroot-2022.02/configs/qemu_arm_vexpress_defconfig) Location to save buildroot config
($(TOPDIR)/../buildroot-dl) Download dir  # 这里我们需要配置Build options，主要是更改Download dir，即buildroot下载文件的存放目录，包括 kernel 源码
($(BASE_DIR)/host) Host dir 
# 选择下载的网址
    Mirrors and Download locations  --->
()  Primary download site 
(http://sources.buildroot.net) Backup download site
(https://cdn.kernel.org/pub) Kernel.org mirror 
(http://ftpmirror.gnu.org) GNU Software mirror 
(http://rocks.moonscript.org) LuaRocks mirror
(http://cpan.metacpan.org) CPAN mirror (Perl packages)
```

- Toolchain配置工具链相关的参数，可以使用外部自己的，也可以网上下载的，又或者直接使用buildroot帮忙编译的

```sh
# 我这里选择 buildroot 自己下载 toolchain , 因为选择额外的会出错
    Toolchain type (Buildroot toolchain)  --->  
     (X) External toolchain 
     Toolchain (Custom toolchain)  ---> 
     Toolchain origin (Pre-installed toolchain)  --->
   (/home/book/kenspace/linux-kernel/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf) Toolchain path  
  ($(ARCH)-linux-gnueabihf) Toolchain prefix 
     External toolchain gcc version (7.x)  --->
     External toolchain kernel headers series (4.10.x)  ---> 
     External toolchain C library (glibc/eglibc)  ---> 
  [*] Toolchain has SSP support? (NEW) 
  [*]   Toolchain has SSP strong support? (NEW) 
  [*] Toolchain has RPC support? (NEW) 
```

- System configuration配置文件系统相关的参数

- Kernel配置内核相关信息，比如源码位置、生成文件、加载地址等等

```
[*] Linux Kernel 
   Kernel version (Custom tarball)  --->  
  (https://mirror.tuna.tsinghua.edu.cn/kernel/v5.x/linux-5.15.tar.xz) URL of custom kernel tarball 
(vexpress) Defconfig name 
      Kernel compression format (gzip compression)  --->
[*]   Build a Device Tree Blob (DTB)
 (vexpress-v2p-ca9) In-tree Device Tree Source file name
```

- Target packages是buildroot配置应用包的地方，后面需要用到的很多应用都可以直接配置，包括像opencv这样的库，当然也可以自己添加配置应用包

- Filesystem images主要设置的是文件系统的镜像格式，可以根据需要使用yaffs2、initial RAM等等格式

···
 [*] ext2/3/4 root filesystem  
       ext2/3/4 variant (ext2 (rev1))  ---> 
···

- Bootloaders 主要配置的启动引导方式

## 配置kernel参数

我们可以提前去网上下载 kernel 到 buildroot-dl/linux/linux-5.15.tar.xz  这样编译的时候会方便很多

## 编译 

```sh
build-vexpressa9$ ./build.sh -j4
```

- 如果报错： multiple (or no) load addresses: 
 
```sh
 ./build.sh LOADADDR=0x80008000 -j4
```

- fakeroot: preload library `libfakeroot.so' not found, aborting.

sudo apt-get install fakeroot

如果还不行，尝试安装：

sudo apt-get install cramfsprogs

之后只需要修改  build-vexpressa9/output-vexpress-v2p-ca9/build/linux-custom 这里的 kernel 源码即可

然后再 ./build.sh linux-rebuild

可能需要移除掉之前安装多余的 gcc ,根据提示操作

```
sudo apt autoremove cpp-7-aarch64-linux-gnu 
sudo apt autoremove cpp-aarch64-linux-gnu 
sudo apt autoremove gcc-7-aarch64-linux-gnu 
sudo apt autoremove gcc-7-aarch64-linux-gnu-base 
sudo apt autoremove libasan4-arm64-cross 
sudo apt autoremove libatomic1-arm64-cross 
sudo apt autoremove libc6-arm64-cross libc6-dev-arm64-cross
sudo apt autoremove libgcc-7-dev-arm64-cross 
sudo apt autoremove libgcc1-arm64-cross 
sudo apt autoremove libgomp1-arm64-cross 
sudo apt autoremove libitm1-arm64-cross 
sudo apt autoremove liblsan0-arm64-cross 
sudo apt autoremove libstdc++6-arm64-cross 
sudo apt autoremove libtsan0-arm64-cross 
sudo apt autoremove libubsan0-arm64-cross 
sudo apt autoremove linux-hwe-5.4-headers-5.4.0-139
sudo apt autoremove linux-libc-dev-arm64-cross
```


再不行可能需要删除原来编译的 rootfs 

```
build-vexpressa9/output-vexpress-v2p-ca9$ mv images images-bak
```

## 运行 qemu

 cd output-vexpress-v2p-ca9/images
 vi kernel-qemu.sh


```sh
#!/bin/sh
IMAGE_DIR="${0%/*}/"
BUILD_ROOTDIR=`realpath ../`
echo $BUILD_ROOTDIR
cp $BUILD_ROOTDIR/build/linux-custom/arch/arm/boot/zImage .
#cp $BUILD_ROOTDIR/build/linux-custom/arch/arm/boot/uImage .
cp $BUILD_ROOTDIR/build/linux-custom/arch/arm/boot/dts/vexpress-v2p-ca9.dtb .

if [ "${1}" = "only" ]; then
    EXTRA_ARGS='-nographic'
else
    EXTRA_ARGS='-serial stdio'
fi

export PATH="/home/vencol/code/vexpressa9/output-vexpress-v2p-ca9/host/bin:${PATH}"
exec   qemu-system-arm -M vexpress-a9 -smp 1 -m 256 -kernel ${IMA1GE_DIR}/zImage -dtb ${IMAGE_DIR}/vexpress-v2p-ca9.dtb -drive file=${IMAGE_DIR}/rootfs.ext2,if=sd,format=raw -append "console=ttyAMA0,115200 rootwait root=/dev/mmcblk0"  -net nic,model=lan9118 -net user  ${EXTRA_ARGS}
```

```
chmod +x kernel-qemu.sh

./kernel-qemu.sh only
```


---

# **进程原理和系统调用**

## 进程概述

> **什么是进程？**

进程: 直观的说，就是保存在硬盘中的程序在运行以后，那么这个运行起来的执行程序就是进程了。另外，操作系统会以进程为单位进行分配资源，比如说CPU时间片，内存等资源。进程是资源分配的最小单位。

> **进程的生命周期**

系统中的每个进程能够分时复用 CPU 的时间片，所以操作系统必须要设计有效的进程调策略实现多任务并行执行。进程在被 CPU 调度运行时有不同的状态。

- 创建状态
- 就绪状态：获取到了运行资源和运行条件
- 执行状态：进程正在 CPU 中执行操作
- 阻塞状态：进程因资源被占用而释放 CPU
- 终止状态：进程终止

在 linux 内核中提供 API 函数来设置进程的状态

- TASK_RUNNING：可运行状态，进程要么在CPU上执行，要么准备执行。
- TASK_INTERRUPTIBLE：可中断的等待状态，进程被挂起(睡眠)，直到某个条件为真，产生一个硬中断、释放进程正等待的系统资源、或传递一个信号都是可以唤醒进程的条件。
- TASK_UNINTERRUPTIBLE：不可中断的等待状态，与可中断等待状态类似，只是不能被信号唤醒。在一些特殊情况下会使用，例如：当进程打开一个设备文件，设备驱动会开始探测相应的硬件时会用到这种状态。
- TASK_STOPED：暂停状态，当进程接收到SIGSTOP、SIGTSTP、SIGTTIN或SIGTTOU信号后进入。
- TASK_TRACED：跟踪状态，进程执行由debugger程序暂停，当一个进程被另一个进程监控时，任何信号都可以把这个进程置于TASK_TRACED状态。

还有两个状态是既可以存放在进程描述符的 state 字段中，也可以存放在 exit_state 字段中。从这两个字段可以看出，只有当进程执行被终止时，进程的状态才会为这两种状态中的一种：

- EXIT_ZOMBIE：僵死状态，进程将被终止，但父进程还没有发布 wait4() 或者 waitpid() 系统调用来返回关于死亡进程的信息。发布 wait() 类系统调用之前，内核不能丢弃包含在死进程描述符中的数据，因为父进程可能还需要它。(一般出现这种状态的原因都是父进程没有响应子进程的死亡信号,可能父进程处于 TASK_INTERRUPTIBLE 状态或者 TASK_UNINTERRUPTIBLE 状态)
- EXIT_DEAD：僵死撤销状态，进程被终止后的最终状态，父进程发布 wait4() 或者 waitpid() 系统调用后，内核删除此进程描述符。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/%E8%BF%9B%E7%A8%8B%E7%8A%B6%E6%80%81.png)

> 我们使用一个简单地例子说明这种状态的转变，我们有个程序A，它的工作就是做一些计算，然后把计算结构写入磁盘文件中。我们在 shell 中运行它，起初它就是 TASK_RUNNING 状态，也就是运行态，CPU 会不停地分配时间片供我们的进程 A 运行，每次时间片耗尽后，进程 A 都会转变到就绪态(实际上还是 TASK_RUNNING 状态，只是此时在等待 CPU 分配时间片，暂时不在 CPU 上运行)。当进程 A使 用 fwrite 或 write 将数据写入磁盘文件时，就会进入阻塞态( TASK_INTERRUPTIBLE 状态)，而磁盘将数据写入完毕后，会通过一个中断告知内核，内核此时会将进程A的状态由阻塞态( TASK_INTERRUPTIBLE )转变为就绪态( TASK_RUNNING )等待CPU分配时间片运行。而最后当进程 A 需要退出时，内核先会将其设置为僵死状态( EXIT_ZOMBIE )，这时候它所使用的内存已经被释放，只保留了一个进程描述符供父进程使用，最后当父进程(也就是我们起初启动它的 shell )通过 wait() 类系统调用通知内核后，内后会将进程A设置为僵死撤销状态( EXIT_DEAD )，并释放其进程描述符。到这里进程 A 的整个运行周期完整结束。

> **Linux 中进程表示**

为了描述控制进程的运行，系统中存放进程的管理和控制信息的数据结构（`task_struct`）称为**进程的控制块** PCB（Process Control Block），它是进程实体的一部分，是操作系统中重要的数据结构。也就是说一个`task_struct`  就是一个 PCB ，我们在调用 `fork()` 的时候，系统就会产生一个 stsk_struct 结构，然后从父进程那你继承一些数据，并把新创建的进程插入到进程数中 。

> task_struct 在文件 include/linux/sched.h 中，成员介绍可以参考：https://www.cnblogs.com/JohnABC/p/9084750.html



## 进程优先级

通过 ps -le 命令

```sh
$ ps -le | head
F S   UID    PID   PPID  C PRI  NI ADDR SZ WCHAN  TTY          TIME CMD
4 S     0      1      0  0  80   0 - 56554 -      ?        00:00:36 systemd
1 S     0      2      0  0  80   0 -     0 -      ?        00:00:00 kthreadd
1 I     0      3      2  0  60 -20 -     0 -      ?        00:00:00 rcu_gp
1 I     0      4      2  0  60 -20 -     0 -      ?        00:00:00 rcu_par_gp
1 I     0      6      2  0  60 -20 -     0 -      ?        00:00:00 kworker/0:0H-kb
1 I     0      9      2  0  60 -20 -     0 -      ?        00:00:00 mm_percpu_wq
1 S     0     10      2  0  80   0 -     0 -      ?        00:00:04 ksoftirqd/0
1 I     0     11      2  0  80   0 -     0 -      ?        00:00:21 rcu_sched
1 S     0     12      2  0 -40   - -     0 -      ?        00:00:00 migration/0
```

上面的输出中，PRI 表示 Priority ， NI 表示 Nice ， 这两个值表示优先级，数字越小代表这个进程优先级越高，也就是越优先被 CPU 处理，不过 PRI 值是由内核动态调整的，用户不能直接修改，所以用户层只能通过修改 NI 值来影响 PRI 值，间接地调整进程优先级。

PRI 和 NI 的关系如下：

PRI (最终值) = PRI (原始值) + NI

> 其实，大家只需要记得，在用户态，我们修改 NI 的值就可以改变进程的优先级。NI 值越小，进程的 PRI 就会降低，该进程就越优先被 CPU 处理；反之，NI 值越大，进程的 PRI 值就会増加，该进程就越靠后被 CPU 处理。

**修改 NI 值时有几个注意事项：**

- NI 范围是 -20~19 。
- 普通用户调整 NI 值的范围是 0~19，而且只能调整自己的进程。
- 普通用户只能**调高** NI 值，而**不能降低**。如原本 NI 值为 0，则只能调整为大于 0。
- 只有 root 用户才能设定进程 NI 值为负值，而且可以调整任何用户的进程。


> **task_struct 中描述进程优先级的成员如下：**

```c
int                             prio; 
int                             static_prio;
int                             normal_prio;
unsigned int                    rt_priority;
```


<table>
	<tr>
	    <th >优先级</th>
	    <th>限期进程</th>
	    <th>实时进程</th>  
      <th>普通进程</th>  
	</tr >
	<tr>
      <th>prio</th>
      <td colspan="3">大多数情况下， `prio = normal_prio` ，特殊情况下，如果进程 A 占用实时互斥锁，进程 B 正在等待锁，进程 B 的优先级就比进程 A 优先级低，那么把进程 A 的优先级临时提高到 A 进程 的优先级，那么进程 A 的 prio 就等于进程 B 的 prio</td>
	</tr >
	<tr>
	    <th>static_prio</th>
	    <td>没有意义 0</td>
	    <td>没有意义 0</td>
	    <td>120*ni, 数值越小，优先级越高</td>
	</tr >
	<tr>
	    <th>normal_prio</th>
	    <td>-1</td>
	    <td>99 - rt_priority</td>
	    <td>static_prio</td>
	</tr >
	<tr>
	    <th>rt_priority</th>
	    <td>没有意义 0</td>
	    <td>实时进程的优先级，范围1-9， 数值越大，优先级越高</td>
	    <td>没有意义 0</td>
	</tr >
</table>


## CFS 调度器


# ARM 中的中断

> **什么是中断？**

从本质上来讲，中断是一种电信号，当设备有某种事件发生时，它就会产生中断，通过总线把电信号发送给中断控制器。中断控制器就把电信号发送给处理器的某个特定引脚。处理器于是立即停止自己正在做的事，跳到中断处理程序的入口点，进行中断处理。

<strong><font color="orange" size="4">
外设 --（电信号）--> 中断控制器 --（中断线是否激活？）--> CPU 的引脚 ---> 停止当前的任务 ---> 处理中断
</font></strong>


从软件方面，在 CPU 正常运行期间，由于内部或者外部事件引起 CPU 暂时停止正在运行的程序，转去这个内部或者外部事件程序中去执行，服务完这个事件程序之后再返回继续运行被暂停的程序。

### 硬中断 和 软中断

中断可分为：**硬件中断（可屏蔽）** 和 **软中断（不可屏蔽）**

- **硬件中断**（hardware interrunpt）: 由与系统相连的**外设**(比如网卡、硬盘)自动产生的。主**要是用来通知操作系统系统外设状态的变化**。比如当网卡收到数据包的时候，就会发出一个中断。我们通常所说的中断指的是硬中断(hardirq)。

- **软中断**（SoftIRQ）: 为了满足实时系统的要求，中断处理应该是越快越好。linux为了实现这个特点，当中断发生的时候，硬中断处理那些短时间就可以完成的工作，而将那些处理事件比较长的工作，放到中断之后来完成，也就是软中断(softirq)来完成。
  - 软中断处理硬中断未完成的工作，是一种推后执行的机制，属于**下半部**

另外需要注意的是，Linux 下硬中断是可以嵌套的，但是没有优先级的概念，也就是说任何一个新的中断都可以打断正在执行的中断，但同种中断除外。软中断不能嵌套，但相同类型的软中断可以在不同 CPU 上并行执行。


### 不可屏蔽中断 和 可屏蔽中断

中断可分为 **不可屏蔽中断 NMI** 和 **可屏蔽中断 INTR**，NMI 用于紧急情况的故障处理，如R AM 奇偶校验错等，INTR 则用于外部依靠中断来工作的硬件设备。网卡使用的就是 INTR，

> 不可屏蔽中断源一旦提出请求，cpu必须无条件响应，而对于可屏蔽中断源的请求，cpu可以响应，也可以不响应。 

CPU 一般会设置 2 根中断请求输入线


- 可屏蔽中断 INTR(Interrupt Require)

除了受本身的屏蔽位的控制外，还都要受一个总的控制，即CPU标志寄存器中的中断允许标志位IF(Interrupt Flag)的控制，IF位为1，可以得到CPU的响应，否则，得不到响应。IF位可以有用户控制，指令STI或Turbo c的Enable()函数，将IF位置1(开中断)，指令CLI或Turbo_c 的Disable()函数，将IF位清0(关中断)。典型的非屏蔽中断源的例子是电源掉电，一旦出现，必须立即无条件地响应，否则进行其他任何工作都是没有意义的。

- 不可屏蔽中断请求 NMI(Nonmaskable Interrupt)

典型的可屏蔽中断源的例子是打印机中断，CPU 对打印机中断请求的响应可以快一些，也可以慢一些，因为让打印机等待儿是完全可以的。

### 相关问题

> 对于软中断，I/O操作是否是由内核中的I/O设备驱动程序完成？

答：对于I/O请求，内核会将这项工作分派给合适的内核驱动程序，这个程序会对I/O进行队列化，以可以稍后处理（通常是磁盘I/O），或如果可能可以立即执行它。通常，当对硬中断进行回应的时候，这个队列会被驱动所处理。当一个I/O请求完成的时候，下一个在队列中的I/O请求就会发送到这个设备上。

> 软中断所经过的操作流程是比硬中断的少吗？换句话说，对于软中断就是：进程 ->内核中的设备驱动程序；对于硬中断：硬件->CPU->内核中的设备驱动程序？

答：是的，软中断比硬中断少了一个硬件发送信号的步骤。产生软中断的进程一定是当前正在运行的进程，因此它们不会中断CPU。但是它们会中断调用代码的流程。



## 中断处理过程