# linux 学习笔记


---

# 今年的任务

- 零声学院+博客网址，需要认真看完： http://www.wowotech.net/sort/memory_management
  - 内存管理
  - 中断子系统
  - 设备子系统

- 音频子系统： lsken00 书签 -- 完成

- 《USB开发大全》

- 在 B站 上学习芯片硬件知识

- 研究C语言
  - 《C 陷阱与缺陷》
  - 《C 编程专家》

- 学习 ARM 汇编，整理面试题

- 学习嵌入式系统架构，bootloader + kernel 启动流程

- 顺序：
  - 1. 音频子系统  已完成
  - 2. 内存管理，USB 开发
  - 3. 芯片知识
  - 4. 中断子系统
  - 5. 设备驱动子系统
  - 6. ARM 汇编
  - 7. C 语言

----

# 安装和编译自己的内核 (TODO)

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

# 进程原理和系统调用 (TODO)

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


# ARM 中的中断(TODO)

> **什么是中断？**

从本质上来讲，中断是一种电信号，当设备有某种事件发生时，它就会产生中断，通过总线把电信号发送给中断控制器。中断控制器就把电信号发送给处理器的某个特定引脚。处理器于是立即停止自己正在做的事，跳到中断处理程序的入口点，进行中断处理。

<strong><font color="orange" size="4">
外设 --（电信号）--> 中断控制器 --（中断线是否激活？）--> CPU 的引脚 ---> 停止当前的任务 ---> 处理中断
</font></strong>


从软件方面，在 CPU 正常运行期间，由于内部或者外部事件引起 CPU 暂时停止正在运行的程序，转去这个内部或者外部事件程序中去执行，服务完这个事件程序之后再返回继续运行被暂停的程序。

### 硬中断 和 软中断

中断可分为：**硬件中断** 和 **软中断**

- **硬件中断**（hardware interrunpt）: 由与系统相连的**外设**(比如网卡、硬盘)自动产生的。主**要是用来通知操作系统系统外设状态的变化**。比如当网卡收到数据包的时候，就会发出一个中断。我们通常所说的中断指的是硬中断(hardirq)。

- **软中断**（SoftIRQ）: 为了满足实时系统的要求，中断处理应该是越快越好。linux为了实现这个特点，当中断发生的时候，硬中断处理那些短时间就可以完成的工作，而将那些处理事件比较长的工作，放到中断之后来完成，也就是软中断(softirq)来完成。
  - 软中断处理硬中断未完成的工作，是一种推后执行的机制，属于**下半部**

另外需要注意的是，Linux 下硬中断是可以嵌套的，但是没有优先级的概念，也就是说任何一个新的中断都可以打断正在执行的中断，但同种中断除外。软中断不能嵌套，但相同类型的软中断可以在不同 CPU 上并行执行。


### 不可屏蔽中断 和 可屏蔽中断

硬件中断可分为 **不可屏蔽中断 NMI** 和 **可屏蔽中断 INTR**，NMI 用于紧急情况的故障处理，如R AM 奇偶校验错等，INTR 则用于外部依靠中断来工作的硬件设备。网卡使用的就是 INTR，

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

### linux 源码中的软中断和硬中断

https://zhuanlan.zhihu.com/p/85597791

## 中断向量表

https://blog.csdn.net/honour2sword/article/details/40213417?spm=a2c6h.12873639.article-detail.5.7ff61d90Ok7ugZ

## 中断控制器是及中断域

https://blog.csdn.net/u013836909/category_10181523.html

GIC 架构规范， 

## 中断处理过程

每个中断都维护一个状态机，支持Inactive、Pending、Active、Active and pending。 中断处理的状态机如下图：

![](https://doc.embedfire.com/linux/rk356x/driver/zh/latest/_images/interr05.png)


- Inactive：无中断状态，即没有 Pending 也没有 Active。

- Pending：硬件或软件触发了中断，该中断事件已经通过硬件信号通知到 GIC，等待 GIC分配的那CPU进行处理，在电平触发模式下，产生中断的同时保持Pending状态。

- Active：CPU已经应答该中断请求，并且正在处理中。

- Active and pending：当一个中断源处于Active状态的时候，同一中断源又触发了中断，进入pending状态，挂起状态。

**一个简单的中断处理过程是**：外设发起中断，发送给Distributor ，Distributor并基于它们的中断特性(优先级、是否使能等等)对中断进行分发处理，分发给合适的Redistributor， Redistributor 将中断信息，发送给 CPU interface，CPU interface产生合适的中断异常给处理器，处理器接收该异常，最后软件处理该中断。

##  Linux 系统对中断处理的方式

### softirq（性能好）

### tasklet（易用）

### workqueue

### threaded irq

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
- 主机控制器驱动：不同的 USB 主机控制器不同（DHCI、EHCI、UHCI、XHCI）,统称 HDC

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

sudo modprobe usbmon
sudo cat /sys/kernel/debug/usb/usbmon/<bus_number>t<device_address>

其中 <bus_number> 和 <device_address> 分别是设备所连接的总线编号和设备地址。例如，如果设备连接在总线 1，地址为 2，则应该输入以下命令：

sudo cat /sys/kernel/debug/usb/usbmon/1t2

这将在终端上打印出所有的 USB 数据包，其中包括 SOF 数据包。

过滤 SOF 数据包
如果只想查看 SOF 数据包，可以使用以下命令过滤：

sudo cat /sys/kernel/debug/usb/usbmon/<bus_number>t<device_address> | grep "SOF"

这将只显示包含 SOF 的数据包。

注意：usbmon 工具需要 root 权限才能使用。





------------

# 音频子系统

## UAC2


UVC（USB Audio Class）定义了使用USB协议播放或采集音频数据的设备应当遵循的规范。目前，UAC协议有UAC1.0和UAC2.0。UAC2.0协议相比UAC1.0协议，提供了更多的功能，支持更高的带宽，拥有更低的延迟。Linux内核中包含了UAC1.0和UAC2.0驱动，分别在f_uac1.c和f_uac2.c文件中实现。这里主要以UAC2驱动为例，具体分析 USB 设备驱动的初始化、描述符配置、数据传输过程等。 

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


### uac2驱动通过configfs的配置

> 参考来源： https://blog.csdn.net/u011037593/article/details/121458492

uac2驱动通过configfs的配置过程如下图所示，创建functions调用uac2驱动的afunc_alloc_inst函数，关联functions和配置时调用uac2驱动的afunc_alloc，使能gadget设备调用uac2驱动的afunc_bind函数，下面分析这三个函数的执行过程。

![](https://img-blog.csdnimg.cn/bbe66e10d68a4c2dae940fb97b77b546.png#pic_center)

USB 设备的枚举实质上是响应 USB 主机发送请求的过程。对于一些标准的 USB 请求，如 USB_REQ_GET_STATUS、USB_REQ_CLEAR_FEATURE 等，USB 设备控制器驱动就可以处理，但有一些标准的USB请求，如 USB_REQ_GET_DESCRIPTOR，需要 USB gadget 驱动参与处理，还有一些 USB 请求，需要 function 驱动参与处理。如下图所示，当主机发送 USB_REQ_GET_CONFIGURATION 或 USB_REQ_SET_INTERFACE 请求时，需要调用 uac2 驱动的 afunc_set_alt 函数处理，当主机发送 USB_REQ_GET_INTERFACE 请求时，需要调用 afunc_get_alt 函数处理，其他USB类请求命令，调用 afunc_setup 处理。

![](https://img-blog.csdnimg.cn/5f5a6db95d1b4a4b9640be663fdd3f2b.png#pic_center)

> **UAC2设备被枚举的过程如下（这里只说明uac2驱动参与处理的部分）：**

- 设置配置

主机发送 USB_REQ_GET_CONFIGURATION 命令设置设备当前使用的配置。uac2 驱动只有一个配置，因此只需要调用 afunc_set_alt 将配置下面所有接口的 alt 值设置为 0。afunc_set_alt 函数的执行流程如下图所示。若是音频控制接口，alt=0 时，直接返回 0，其他值直接报错；若是音频流**输出接口**，alt=0 时，停止录音，alt=1 时，开始录音；若是音频流**输入接口**，alt=0 时，停止播放，alt=1 时，开始播放。

![](https://img-blog.csdnimg.cn/b64cc232240346e28a876f8ec606bb15.png#pic_center)

### 工作过程分析

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

-----

## ALSA 电源管理 DAPM

ALSA 主要是通过 DAPM 进行电源管理

DAPM（Dynamic Audio Power Management）是 ALSA 中的一种动态音频功率管理机制，它可以根据音频设备的使用情况动态地调整设备的电源状态，以达到节能和延长设备寿命的目的。

DAPM 是为了使基于 linux 的移动设备上的音频子系统在任何时候都工作在最小功耗状态下。DAPM 对用户空间的应用程序来说是透明的，所有与电源相关的开关都在 ASoc core 中完成。用户空间的应用程序无需对代码做出修改，也无需重新编译，DAPM 根据当前激活的音频流（playback/capture）和声卡中的 mixer 等的配置来决定那些音频控件的电源开关被打开或关闭。

> Mixer 是一种硬件或软件设备，用于混合多个音频信号并将它们输出到单个音频输出设备。Mixer 可以将多个音频源（例如麦克风、音乐播放器、电视等）的音频信号混合在一起，并通过单个音频输出设备（例如扬声器、耳机等）输出混合后的音频信号。
>


----

# 内存管理

- 物理地址空间

处理器对外设寄存器编址方式分为两种： I/O 映射方式 和 内存映射方式。

应用程序只能通过虚拟地址访问外设，内核会提供外设物理地址映射成虚拟地址的 API 。

- 内存映射原理

 
