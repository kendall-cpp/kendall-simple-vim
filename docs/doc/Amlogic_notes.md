
# dump寄存器

## i2c寄存器

```sh
i2cdump -f -y 0x01 0x2d
```

## korlan tdm 寄存器

```sh
# 28 表示 dump 出多少个寄存器，后面cat 出来，用计算器查看对应二进制位
echo 0xfe0501c0 10 > /sys/kernel/debug/aml_reg/dump
echo 0xfe050540 28 > /sys/kernel/debug/aml_reg/dump
cat /sys/kernel/debug/aml_reg/dump 
```

如果没有 /sys/kernel/debug/aml_reg/dump 这文件夹，是因为 debugfs 没有 mount 起来

```sh
/ # mount -t debugfs none /sys/kernel/debug
/ # mount | grep debug 
none on /sys/kernel/debug type debugfs (rw,relatime)
```

# audio 工具使用

> 上传音频数据 adb push .\the-stars-48k-60s.wav /data/

## arecord与aplay

```sh
arecord  -l  # 查询 linux 系统下设备声卡信息

arecord -D hw:0,0 -r 16000 -c 1 -f S16_LE test.wav  # 录制音频

Recording WAVE 'test.wav' : Signed 16 bit Little Endian, Rate 16000 Hz, Mono
^CAborted by signal Interrupt...  # 这里使用Ctrl+c 结束了录制

aplay -l # 查看播放设备
aplay -Dhw:0,0 /data/the-stars-48k-60s.wav   # 播放音频
```

## amixer

- amixer controls 用于查看音频系统提供的操作接口
- amixer contents 用于查看接口配置参数
- amixer cget + 接口函数
- amixer cset + 接口函数 + 设置值


```sh
dmesg  -n 8   # 开 log
amixer cget numid=2       # 查看音量
amixer cset numid=2 150   # 修改音量
amixer cset numid=3  on
amixer cset numid=5 on 
# 或者
amixer cset numid=2,iface=MIXER,name='tas5805 Digital Volume' 150

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav

echo 0 > /sys/module/u_audio/parameters/free_run  & aplay -Dhw:0,0 /data/the-stars-48k-60s.wav & echo 1 > /sys/module/u_audio/parameters/free_run 
```

# tdm_bridge -korlan

usb_audio 才走 tdm_bridge, aplay 直接 tdm.c

```sh
# 强制启动和关闭tdm_bridge
echo 0 > /sys/module/u_audio/parameters/free_run   
echo 1 > /sys/module/u_audio/parameters/free_run  
```

# Enable usb 以太网

- 需要打开配置

```sh
# korlan
arch/arm64/configs/korlan-p2_defconfig
CONFIG_USB_RTL8152=y
```

- 开机自动获取 ip ， 需要启动 dhcpcd 服务

```sh
on post-fd
        exec /bin/sh -c "echo 1 > /sys/kernel/debug/usb_mode/mode"

# start dhcpcd                           
start dhcpcd
```

## adb connect

adb coonect 默认使用的是 ipv6，所以需要打开 ipv6 才能使用

enable ipv6 可以参考这个 patch

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/260551
```

# Ubuntu 工具

## 在 Ubuntu/PC 下进入开发板

连接串口和 USB

> adb shell

## python 打印行号

```py
print('Print Message: lsken00 ========>  ' + ' ,File: "'+__file__+'", Line '+str(sys._getframe().f_lineno)+' , in '+sys._getframe().f_code.co_name)
```

## 查看kernel编译的版本

```sh
getprop | grep elaine
```

## 打印函数调用栈

打印函数追踪 追踪函数调用

```sh
dump_stack();
```

## 关于寄存器一些操作

```c
printk("reg:0x%02x", addr);   // u16 addr 
```

### __iomem

__iomem是linux2.6.9内核中加入的特性。是用来个表示指针是指向一个I/O的内存空间。主要是为了驱动程序的通用性考虑。由于不同的CPU体系结构对I/O空间的表示可能不同。

当使用__iomem时，编译器会忽略对变量的检查（因为用的是void __iomem）。若要对它进行检查，当__iomem的指针和正常的指针混用时，就会发出一些警告。

## 修改 u-boot BOOTDELAY 时间

```sh
vim spencer-sdk/u-boot/board/amlogic/defconfigs/c2_venus_p2_defconfig

CONFIG_SCHUMACHER_SSR=y
CONFIG_BOOTDELAY=5  
CONFIG_ENABLE_UBOOT_CLI=y
```

## 查看二进制文件

### 查看依赖和编译器 readelf strings

```
 # 查看依赖的库
 readelf -d libOpenVX.so | grep NEEDED
 
 # 看GLIB版本信息
 strings libOpenVX.so | grep GLI
  # 看GCC版本信息
 strings libOpenVX.so | grep GCC
```

### 对比二进制文件 hexdump


- 第一种方法： 将后缀改成一样然后用 compare 工具比较
- 第二种方法：

```sh
hexdump -C system_1.bin > system_1.bin.txt 
hexdump -C erofs.img > erofs.img.txt 
vim -d erofs.img.txt  system_1.bin.txt 
```

----

# linux 调试工具使用

## top

```sh
# 在某个程序运行期间执行，比如：在push期间执行下面命令检测
top -m 5 -t
```


### top 命令详解

top命令经常用来监控linux的系统状况，是常用的性能分析工具，能够实时显示系统中各个进程的资源占用情况。

```c
//总的统计
User 37%, System 25%, IOW 0%, IRQ 0%
User 231 + Nice 2 + Sys 157 + Idle 222 + IOW 3 + IRQ 0 + SIRQ 0 = 615


//每个进程
  PID PR CPU% S  #THR     VSS     RSS PCY UID      Name
18170  0  34% S   155 1906448K 246152K  fg u0_a369  com.icongtai.zebra.car
  310  1   8% S    31 651920K  12884K  fg system   /system/bin/surfaceflinger
21024  1   4% S     1      0K      0K  fg root     kworker/u17:1
22231  1   3% S     1      0K      0K  fg root     kworker/u17:2
 7922  0   1% S     5  17260K    728K  fg shell    /sbin/adbd
```

### 输出参数说明

#### 系统的总的统计信息说明

- User : 用户进程的使用率
- System : 系统进程的使用率
- Nice : 优先值为负的进程所占用的CPU时间
- IOW : IO wait的等待时间
- IRQ : 硬中断时间
- SIRQ : 软中断的含义
- Idle : 除IOW以外的系统闲置时间

#### 每个进程的描述说明

- PID : 进程ID
- USER(UID) : 进程所有者的ID
- PR : 进程优先级
- CPU% : CPU占用率。
- S : 进程状态 D=不可中断的睡眠状态 R=运行 S=睡眠 T=跟踪/停止 Z=僵尸进程
- #THR : 程序当前所用的线程数
- VSS : Virtual Set Size 虚拟内存
- RSS : Resident Set Size 实际使用的物理内存
- PCY : 线程调度策略
- Name : 进程名字

### 命令格式

```
top [-d number] 或者 top [-bnp]
```

选项说明

> 注意嵌入式系统可能一些参数被去掉，无法使用

```sh
top -d 10  # number代表秒数，表示top命令显示的页面更新一次的间隔，默认是 3 秒。

top -c     # 每隔3秒显示进程的资源占用情况，并显示进行的命令行参数

top -p 8080 -p 8081    # 每隔3秒显示pid是8080 和 pid 是 8081 这两个进程的资源占用情况

top -d 2 -c -p 8080    # 每隔2秒显示pid是 8080 的进程资源使用情况，并显示该进程启动的命令行参数

top -m  -d 10 -b > top.log  # -d 是间隔秒数 -b 写入文件 -m 参数可以很好的观察各个进程在压力测试过程中的变化

top -m 5 -t   # 在压力测试时，top5 进程的 线程信息
```


 top -m 5 -d 10 -n 1 -s cpu


| 列名   |         含义 | 实例 |
| ---  | ---  | --- |
| -m   | max_procs最多显示多少个进程 | -m 1 显示1个进程  |
| -n   | iterations 刷新次数 | -n 10 只输出10次 |
| -d   | delay 刷新的间隔时间，单位是秒 默认是5秒 | -d 10 每隔10秒刷新一次 |
| -s   | 输出的数据按照那一列排序 | -s cpu 标识按照CPU排序。  |
| -t   | 显示线程信息，而不是进程 | |
| -h   | 显示帮助文档。 | |


```
top -p `ps aux | grep "xxx" | grep -v grep | cut -c 9-15`
```

- top -p：指定进程
- top -d 1：指定屏幕刷新时间，1s刷新一次
- top -b：表示以批处理模式操作
- ps aux：列出所有进程
- grep：查找指定进程
- grep -v：反向查找
- cut -c 9-15：选择每行指定列的字符

## perf

### korlan 编译 perf

kernel 使用 perf 需要打开 ftrace， 可以参考这个 patch 进行打开

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/239808
```

- 编译 perf

```sh
# 编译， kernel-5.15 也类似
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/kernel$ ./build_perf.sh korlan ../../chrome
# 编译出来的 perf 在 ./tools/perf

# make CROSS_COMPILE=./prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu- ARCH=arm64 LDFLAGS=-static -C tools/perf
```

如果想在板子上能使用 perf ,可以直接打上这个  patch  开启相应的 config 即可

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/239808

### 在板子上使用 perf

```sh
adb push ./tools/perf/perf /data
chmod 777 /data/perf

# 测试
/data/perf top

# 测试全局函数
cd data
./perf record -e cpu-clock -F 500 -a -g sleep 60
./perf script > out.perf

# 将 out.perf pull 到 /mnt/fileroot/shengken.lin/workspace/github/FlameGraph
adb pull /data/out.perf ./out

./stackcollapse-perf.pl ./out/out.perf > ./out/out.folded
./flamegraph.pl ./out/out.folded > ./out/kernel.svg

# 浏览器打开 kernel.svg
```

- get anaysis perf data tools

https://github.com/brendangregg/FlameGraph

- 查看 追踪 工具

```sh
https://ui.perfetto.dev/
# 要chrome打开
```


### 系统性能分析工具：perf

> 更详细的讲解参考：https://zhuanlan.zhihu.com/p/498100484

perf 是Linux的一款性能分析工具，能够进行函数级和指令级的热点查找，可以用来分析程序中热点函数的CPU占用率，从而定位性能瓶颈。

系统性能优化通常可以分为两个阶段：性能分析和性能优化。

- 性能分析的目的是查找性能瓶颈、热点代码，分析引发性能问题的原因；
- 基于性能分析，可以进行性能优化，包括：算法优化（空间复杂度和时间复杂度的权衡）和代码优化（提高执行速度、减少内存占用）。

Linux性能计数器是一个基于内核的子系统，它提供一个性能分析框架，比如硬件（CPU、PMU（Performance Monitoring Unit））功能和软件（软件计数器、tracepoint）功能。

### perf 的使用

使用 perf 进行性能分析，主要使用下面两个命令：

- perf record：保存 perf 追踪的内容，文件名为 perf.data
- perf report：解析 perf.data 的内容

比如要分析进程 xxx，启动该进程后，首先启动使用下面命令：

```sh
perf record -a --call-graph dwarf -p `ps aux | grep "xxx" | grep -v grep | cut -c 9-15` -d 1 -b 
```

- -a：表示对所有CPU采样
- --call-graph dward：表示分析调用栈的关系
- -p：表示分析指定的进程

运行结束或者通过 Ctrl + C 结束后，会生成 perf.data 文件，然后通过 report 导出报告，即可以查看 main 函数和子函数的CPU平均占用率。

```
perf report -i perf.data > perf.txt
```

#### stat 参数

```
/data # ./perf stat -p 1467
^C
 Performance counter stats for process id '1467':

            293.67 msec task-clock                #    0.042 CPUs utilized          
               146      context-switches          #    0.497 K/sec                  
                 7      cpu-migrations            #    0.024 K/sec                  
                 0      page-faults               #    0.000 K/sec                  
         123267078      cycles                    #    0.420 GHz                    
          38987062      instructions              #    0.32  insn per cycle         
           6286641      branches                  #   21.407 M/sec                  
            861473      branch-misses             #   13.70% of all branches        

       7.073559503 seconds time elapsed
```

- task-clock 是指程序运行期间占用了xx的任务时钟周期，该值高，说明程序的多数时间花费在 CPU 计算上而非 IO
- context-switches 是指程序运行期间发生了 xx 次上下文切换，记录了程序运行过程中发生了多少次进程切换，频繁的进程切换是应该避免的。（有进程进程间频繁切换，或者内核态与用户态频繁切换）
- cpu-migrations 是指程序运行期间发生了 xx 次 CPU 迁移，即用户程序原本在一个 CPU 上运行，后来迁移到另一个CPU
- cycles：处理器时钟，一条机器指令可能需要多个 cycles
- Instructions: 机器指令数目。
- 其他可以监控的譬如分支预测、cache命中,page-faults 是指程序发生了 xx 次页错误等

#### perf record 的其他参数

- -f：强制覆盖产生的.data数据
- -c：事件每发生count次采样一次
- -p：指定进程
- -t：指定线程

可以使用 ctrl+c 中断 perf 进程，或者在命令最后加上参数 --sleep n (n秒后停止) 

sudo perf report -n 可以生成报告的预览。
sudo perf report -n --stdio 可以生成一个详细的报告。
sudo perf script 可以 dump 出 perf.data 的内容。

获得这个 perf.data 文件之后，我们其实还不能直接查看，下面就需要 perf report 工具进行查看

perf report 输出 record 的结果

如果record之后想直接输出结果，使用perf report即可

perf report的相关参数：

- -i : 指定文件输出
- -k：指定未经压缩的内核镜像文件，从而获得内核相关信息
- --report：cpu 按照 cpu 列出负载

#### cpu-clock

perf record -e cpu-clock -g -p pid

-e 选项允许您在 perf list 命令中列出的多个类别中选择一个事件类别。

例如，在这里，我们使用 -e cpu-clock 是指 perf record 监控的指标为 cpu 周期程序运行完之后，perf record会生成一个名为 perf.data 的文件（缺省值），如果之前已有，那么之前的 perf.data 文件会变为 perf.data.old 文件 

-g 选项是告诉perf record额外记录函数的调用关系，因为原本perf record记录大都是库函数，直接看库函数，大多数情况下，你的代码肯定没有标准库的性能好对吧？除非是针对产品进行特定优化，所以就需要知道是哪些函数频繁调用这些库函数，通过减少不必要的调用次数来提升性能

```sh
./perf record -e cpu-clock -F 500 -a -g sleep 60  # 采样时间为 60 秒，每秒采样 500 个事件
```

#### perf script

将 perf.data 输出可读性文本 

```sh
./perf script > out.perf
```

#### 生成火焰图

> 需要 git clone https://github.com/brendangregg/FlameGraph

```
# 将 out.perf pull 到 /{yourpatch}/github/FlameGraph
adb pull /data/out.perf ./out

 ./stackcollapse-perf.pl ./out/out.perf > ./out/out.folded
 ./flamegraph.pl ./out/out.folded > ./out/kernel.svg
 ```


## nandread

- korlan 中抓 trace 命令

```sh
抓trace 命令：
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo 0 > /sys/kernel/debug/tracing/events/enable
echo ""  > /sys/kernel/debug/tracing/trace
echo 10240 > /sys/kernel/debug/tracing/buffer_size_kb

echo 1 > /sys/kernel/debug/tracing/options/record-tgid
echo 1 > /sys/kernel/debug/tracing/options/print-tgid
echo 1 > /sys/kernel/debug/tracing/events/ipi/enable
echo 1 > /sys/kernel/debug/tracing/events/cpufreq_interactive/enable
echo 1 > /sys/kernel/debug/tracing/events/irq/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/enable
echo 1 > /sys/kernel/debug/tracing/events/timer/enable
echo 1 > /sys/kernel/debug/tracing/events/power/cpu_idle/enable
echo 1 > /sys/kernel/debug/tracing/events/cpufreq_meson_trace/enable
echo 0 > /sys/kernel/debug/tracing/events/kprobes/enable
echo 0 > /sys/kernel/debug/tracing/events/rcu/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable
echo 0 > /sys/kernel/debug/tracing/events/workqueue/enable

echo 1 > /sys/kernel/debug/tracing/tracing_on
echo "" > /sys/kernel/debug/tracing/trace

# 测试 nandread 的时间； mtd4 没有使用的的分区
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex 

# 等 5秒 按回车

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > /data/trace_01.txt
```

## nandwrite

```sh
需要找一个 write_test_file 文件，往没有使用的分区去写
busybox time nandwrite /dev/mtd/mtd4 -s -0 -p /data/write_test_file 
```

## ftrace

### korlan 打开 trace

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/239808
```



## iozone IO 性能测试


- 下載 iozone3_494.tgz

https://www.iozone.org/src/current/

        或者：wget http://www.iozone.org/src/current/iozone3_487.tar

```sh
tar zxf iozone3_494.tgz 
```

- 下载的源码编译报错

  - 错误 1

```sh
error : /usr/bin/ld: pit_server.o: relocation R_X86_64_32 against symbol `service_name' can not be used when making a PIE object; recompile with -fPIE

chmod +w makefile 
vim makefile
CC  = cc -no-pie 

# CC  = /mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang  


./iozone -i 0 -i 1 -i 2 -s 64g -r 16m -f ./iozone.tmpfile -Rb ./iotest.xls
```

  - 错误 2

```sh
iozone.c:1273:9: error: redeclaration of 'pread64' must have the 'overloadable' attribute
ssize_t pread64(); 
        ^
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/prebuilt/toolchain/aarch64/usr/aarch64-cros-linux-gnu/usr/include/bits/unistd.h:89:1: note: previous overload of function is here
pread64 (int __fd, void *const __clang_pass_object_size0 __buf,
^
1 error generated.
make: *** [makefile:1044: iozone_linux-arm.o] Error 1


修改： vim /mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/prebuilt/toolchain/aarch64/usr/aarch64-cros-linux-gnu/usr/include/bits/unistd.h +89

89 pread64_iozone_test (int __fd, void *const __clang_pass_object_size0 __buf,
          size_t __nbytes, __off64_t __offset) 
```

### iozone 测试

參考： https://www.freesion.com/article/76691495377/

```
./iozone -a -n 4m -g 256m -i 0 -i 1 -y 4096 -q 4096 -f /system/iozone.tmpfile -Rb ./iotest.xls
```



## CPU 占有率

```sh
git clone https://github.com/sysstat/sysstat.git
cd sysstat
./configure

vim makefile
CC  = /mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/prebuilt/toolchain/aarch64/bin/aarch64-cros-linux-gnu-clang  
make 


# 测试
./mpstat -P ALL 10


busybox mpstat -P ALL 10
```

```
第一部分：输出首先显示了所有 CPU 的合计指标，然后显示了每个 CPU 各项的指标。

第二部分：在结尾处显示所有 CPU 的平均值。

各列的含义：

%user: 表示用户态所使用 CPU 的百分比。
%nice: 表示使用 nice 命令对进程进行降级时 CPU 的百分比。
%sys: 表示内核进程使用的 CPU 百分比。
%iowait: 表示等待进行 I/O 所使用的 CPU 时间百分比。
%irq: 表示用于处理系统中断的 CPU 百分比。
%soft: 表示用于软件中断的 CPU 百分比。
%steal:虚拟机强制CPU等待的时间百分比。
%guest: 虚拟机占用CPU时间的百分比。
%idle: CPU 的空闲时间的百分比。
```




-------

# ramdisk init 中增加打印 log

```
write /dev/kmsg "TEST : =============222  lsken00"
```

dmesg 打印内核启动过程的所有信息，/proc/kmsg 也是打印内核的信息， 但是与dmesg 有不同， 第一次执行 /proc/kmsg 打印到目前位置的所有内核信息，再次执行 /proc/kmsg ,

不打印打印过了的信息，打印第一次执行之后的信息，下面举个例子：

第一次执行dmesg打印：

```
A
B 
C
```

第一次执行/proc/kmsg打印：

```
A
B 
C
```

第二次执行dmesg打印：

```
A
B 
C
D
```

第2次执行/proc/kmsg打印：

```
D
```

依次类推。


# erofs 文件系统

参考：

- https://blog.csdn.net/ZR_Lang/article/details/88859477

- https://tjtech.me/how-to-build-mkfs-erofs-for-arm64.html

- https://blog.csdn.net/u014001096/article/details/124831748

- 源码 readme https://android.googlesource.com/platform/external/erofs-utils/+/refs/heads/master/README

## 下载和编译 erofs-utils

```sh
git clone git://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git

# 需要下载一下插件
sudo apt-get install autotools-dev 
sudo apt-get install automake

sudo apt-get install uuid-dev
sudo apt-get install liblz4-dev

apt-cache search liblz4-dev

# 24服务器上没有
sudo apt-get remove liblz4-dev
# 所以可以在 ubuntu 上编译出  mkfs.erofs

 
cd erofs-utils
./autogen.sh
./configure
make -j4

# 如果需要更换编译器
# ./configure --host aarch64-linux-android  & make

cp mkfs.erofs /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/host/linux-x86/bin/ -rf
```

## mkfs.erofs 使用

### 手动 mount erofs

```sh
# 制作 img
# 拷贝一些文件到 srcd
./mkfs.erofs  erofs.img srcd/
adb push erofs.img /data/

# 使用 lz4 压缩，需要观察在 erofs-utils configure时 lz4 是否显示为 yes
./mkfs.erofs -zlz4 -C65536 ./erofs.img.3 ./srcd/ -E context_file_path  # (linux的参数)

mount -t erofs /data/erofs.img  /data/aaa/

# 如果把 img 烧到自己新增加的分区，就这样挂载
mount -t erofs /dev/block/mtdblock8  /data/aaa/
```

**erofs 默认支持 lz4 压缩算法，所以需要安装相应的库，不然 .configure 时会关闭 lz4**



### 修改 ota_from_target_files 支持 erofs

参考这个 patch: https://eureka-partner-review.googlesource.com/q/topic:%22Enable+erofs%22

```sh
# common_drivers
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276586

# kernel-5.15
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276587

# u-boot
https://eureka-partner-review.googlesource.com/c/amlogic/u-boot/+/276588

# vendor/amlogic
https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/276589
```


# 给 korlan 增加一个分区

```
vim  google_source/eureka/korlan-sdk/u-boot/board/amlogic/a1_korlan_p2/a1_korlan_p2.c

vim  kernel-5.15/common_drivers/arch/arm64/boot/dts/amlogic/korlan-common.dtsi
```

在这两个文件下找 partition ，然后计算和修改大小


```sh
@ken@:/mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/kernel-5.15/common_drivers$ git diff
diff --git a/arch/arm64/boot/dts/amlogic/korlan-common.dtsi b/arch/arm64/boot/dts/amlogic/korlan-common.dtsi
index febcc0e872c6..7768e7572c0a 100644
--- a/arch/arm64/boot/dts/amlogic/korlan-common.dtsi
+++ b/arch/arm64/boot/dts/amlogic/korlan-common.dtsi
@@ -663,6 +663,10 @@
                                size=<0x0 0x1E00000>;
                        };
                        cache{
+                               offset=<0x0 0x0>;
+                               size=<0x0 0x3200000>;
+                       };
+                       system_1{
                                offset=<0xffffffff 0xffffffff>;
                                size=<0x0 0x0>;
                        };

@ken@:/mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/u-boot$ git diff
diff --git a/board/amlogic/a1_korlan_p2/a1_korlan_p2.c b/board/amlogic/a1_korlan_p2/a1_korlan_p2.c
index d1a19855a1..b3660ab80d 100644
--- a/board/amlogic/a1_korlan_p2/a1_korlan_p2.c
+++ b/board/amlogic/a1_korlan_p2/a1_korlan_p2.c
@@ -285,12 +285,28 @@ static const struct mtd_partition spinand_partitions[] = {
                .offset = 0,
                .size = 30 * SZ_1M,
        },
-       /* last partition get the rest capacity */
        {
                .name = "cache",
+               .offset = 0,
+               .size = 50 * SZ_1M,
+       },
+       /* last partition get the rest capacity */
+       {
+               .name = "system_1",
                .offset = MTDPART_OFS_APPEND,
                .size = MTDPART_SIZ_FULL,
-       }
+        }
```

- 板子上查看分区

```sh
cat /proc/mtd

# 增加一个 block dev
ls /dev/block/mtdblock8 

# 注意 cache 默认是 mtd7
# 可以在 init.rc 中查看
# exec /bin/sh /sbin/check_and_mount_ubifs.sh 7 cache /cache 20 
```

## 读取分区表

```sh
分区表，
0x000000000000-0x000000200000 : "bootloader"
0x000000800000-0x000001000000 : "tpl"
0x000001000000-0x000001100000 : "fts"
0x000001100000-0x000001500000 : "factory"
0x000001500000-0x000002120000 : "recovery"
0x000002120000-0x000002d20000 : "boot"
0x000002d20000-0x000004be0000 : "system"
0x000004be0000-0x000008000000 : "cache"

step1: 读fts分区到 0x1080000 
E:\amlogic_tools\aml_dnl-win32\adnl.exe oem "store read 0x1080000 fts 0 0x100000"

step2: 从1080000， dump 出 0x100000 到fts.bin.
E:\amlogic_tools\aml_dnl-win32\adnl.exe upload -f fts.bin  -z 0x100000 -m mem -p 0x1080000
```

```sh
/ # cat /proc/mtd 
dev:    size   erasesize  name
mtd0: 00200000 00020000 "bootloader"
mtd1: 00800000 00020000 "tpl"
mtd2: 00100000 00020000 "fts"
mtd3: 00400000 00020000 "factory"
mtd4: 00c20000 00020000 "recovery"
mtd5: 00c00000 00020000 "boot"
mtd6: 01e00000 00020000 "system"
mtd7: 03220000 00020000 "cache"
mtd8: 002c0000 00020000 "system_1"

adnl oem "store read 0x1080000 system_1 0 0x2c0000"
adnl upload -f system_1.bin  -z 0x2c0000 -m mem -p 0x1080000
```

# 更改工厂模式 factory

```sh
cat /proc/fts 
fts -s bootloader.command  # 设置bootloader命令
fts -i  #清除工厂模式
```

# wpa_cli连接wifi

```
wpa_cli -iwlan0 remove_network 0
wpa_cli -iwlan0 add_network 0
wpa_cli -iwlan0 set_network 0 ssid '"Amlogic-vpn04_5G"'
wpa_cli -iwlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -iwlan0 set_network 0 psk '"Aml1234566"' 
wpa_cli -iwlan0 set_network 0 pairwise CCMP
wpa_cli -iwlan0 set_network 0 group CCMP
wpa_cli -iwlan0 set_network 0 proto RSN
wpa_cli -iwlan0 enable_network 0
wpa_cli -iwlan0 status
wpa_cli -iwlan0 save
dhcpcd wlan0

wpa_cli -iwlan0 remove_network 0
wpa_cli -iwlan0 add_network 0
wpa_cli -iwlan0 set_network 0 ssid '"kendall"'
wpa_cli -iwlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -iwlan0 set_network 0 psk '"12345678"' 
wpa_cli -iwlan0 set_network 0 pairwise CCMP
wpa_cli -iwlan0 set_network 0 group CCMP
wpa_cli -iwlan0 set_network 0 proto RSN
wpa_cli -iwlan0 enable_network 0
wpa_cli -iwlan0 status
wpa_cli -iwlan0 save
```

---

# chrome 中打开 kernel log

```sh
vim vendor/amlogic/korlan/BoardConfigCommon.mk  +81

# loglevel=7
```

# 休眠 ARM 运行 dsp

> 基于 venus-p2 测试

```sh
cd freertos
./build_rtos.sh venus-p2 ./../../chrome release --skip-dsp-build
# 输出目录：out_dsp/dspboot.bin

# 运行dsp
adb.exe push ./dspboot.bin  /system/lib/firmware/
adb.exe push ./dspboot.bin  /lib/firmware/

# Run the test
# 1. -s                 : stop dsp
# 2. -r                 : reset dsp
# 3. -l --firmware=XXXX : reload dsp
# 4. -S                 : start dsp
dsp_util --dsp=hifi4a -s
dsp_util --dsp=hifi4a -r
dsp_util --dsp=hifi4a --firmware=dspboot.bin -l
dsp_util --dsp=hifi4a -S

# ARM 进入休眠; 休眠 ARM
echo mem > /sys/power/state
```

---

# JTAG 接口和 SWD 接口

https://support.amlogic.com/issues/18561

- 参考Sonos issues : https://support.amlogic.com/issues/12564#change-89466
- 使用手册：`\\walle01-sz\fileroot\shengken.lin\workspace\Sonos-file\RISC-V_JTAG\OpenOCD\jtag user guide - OpenOCD.pdf`

电脑路径： `\\walle01-sz\fileroot\shengken.lin\workspace\Sonos-file\RISC-V_JTAG`

## OpenOCD安装与使用（JTAG调试）

> 以 A5-Av400 为例

- 在 ubuntu 中下载和编译 openOcd

**第一步**： git clone https://github.com/openocd-org/openocd

> Note1:The version v0.10.0 of OpenOCD(commit:4c364b453488fb5d30c32dfb4f294c30d255d7bf) is work fine, and we recommend using this version.

git reset --hard 4c364b453488fb5d30c32dfb4f294c30d255d7bf

**第二步 编译**

```sh
# 需要下载的 package
sudo apt-get install build-essential pkg-config autoconf automake libtool libusb-dev libusb-1.0-0-dev libhidapi-dev

cd openocd/
sudo ./bootstrap # 可以不使用 sudo
# ./configure --prefix=[specify the install directory] --enable- maintainer-mode --enable-jlink 
mkdir output
sudo  ./configure --prefix=/home/amlogic/Desktop/lsken00/github/Jtag-Jlink/openocd/output/ --enable-jlink
sudo make

sudo make install
```

**第三步 连接和测试 JTAG**

- 找 Zelong Dong（SZ 5楼） 借到 Jlink (ARM 仿真器)

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/图片1.2vnzyxuro7o0.webp)

```sh

cd ~/Desktop/lsken00/github/openocd
mkdir config; cd config
# 从linux中拷贝 OpenOCD 到 ubuntu （\\walle01-sz\fileroot\shengken.lin\workspace\Sonos-file\RISC-V_JTAG\OpenOCD）
7z x OpenOCD_cfg.7z
cp /media/amlogic/RECOVERYUSB/lsken00/Jtag-Jlink-a5-av400/OpenOCD_cfg . -rf
```

> Note1: OpenOCD_cfg.7z is amlogic config file, pls check attachment file.
> Note2: openocd binary under 1.2.2 (--prefix=[specify the install directory]) dirctory.

- 连接 ubuntu 和 av400

- 板子进入 uboot

```sh
a5_av400# jtagon aocpu jtag_a 
bl31: jtag: enable jtag_a (GPIOD) <---> aocpu
a5_av400# 
```

- 在 ubuntu 上测试

```sh
# ~/Desktop/lsken00/github/Jtag-Jlink/openocd
sudo ./output/bin/openocd -f config/OpenOCD_cfg/meson_a5.cf
```

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/jtag2.3rlguhipplc0.webp)

- 不要停止，在 ubuntu 重新开启另一个窗口执行

```sh
telnet localhost 4444

> targets

# enable a5.aocpu
> jtag tapenable a5.aocpu
JTAG tap: a5.aocpu enabled
Unsupported DTM version: 15
1

> targets 0

> halt

> targets

> resume

> targets

# 如果需要 disable 目标板
> jtag tapdisable a5.aocpu
JTAG tap: a5.aocpu disabled
0
```

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/jtag3.25tiil7ey5nk.webp)

### OpenOCD常用命令

```
halt	-暂停CPU
reset	-复位目标板
resume 	-恢复运行
resume 0x123456   -从0x123456地址恢复运行
reg <register>    -打印register寄存器的值

load_image <File Name> <Addr>		    -烧写二进制文件到指定地址
例: load_image image.bin 0x4000000  	-烧写image.bin到0x4000000

dump_image <File Name> <Addr> <Size>    -将内存从地址Addr开始的Size字节数据读出，保存到文件File Name中

verify_image <File Name> <Addr> [bin|ihex|elf] 	-将文件File Name与内存Addr开始的数据进行比较，格式可选，bin、ihex、elf

step [Addr]		-不加地址：从当前位置单步执行; 加地址：从Addr处单步执行
poll		    -查询目标板当前状态
bp <Addr> <Length> [hw] 	-在Addr地址设置断点，指令长度为Length，hw代表硬件断点
rbp <Addr>		 -删除Addr处的断点

mdw <Addr> [Count]	 -显示从物理地址Addr开始的Count(缺省则默认为1)个字（4Bytes）
mdh <Addr> [Count]	 -显示从物理地址Addr开始的Count(缺省则默认为1)个半字（2Bytes）
mdb <Addr> [Count]	 -显示从物理地址Addr开始的Count(缺省则默认为1)个字节（1Byte）
mww <Addr> <Value>   -向物理地址Addr写入Value，大小：一个字（4Bytes）
mwh <Addr> <Value>   -向物理地址Addr写入Value，大小：一个半字（2Bytes）
mwb <Addr> <Value>   -向物理地址Addr写入Value，大小：一个字节（1Bytes）

```

# 通过原理图查看 pinmux 功能

> 以 a5-av400 为例

av400 板子资料下载地址：https://confluence.amlogic.com/pages/viewpage.action?pageId=148280604

- av400 原理图：A113X2_AV400_DEV_LPDDR4_V1.0_R0.5_20211130.pdf

- pinmux 功能表格： A5_core_pinmux_v07_20211229.xlsx

- 某个寄存器，对应的位，默认是 0 ，就是作为普通的 GPIO ， 如果是 1 ，就用 func1 ......

- 查找

  - 如果知道寄存器的地址，比如 fe004040

    - 一般会有偏移，所以可以去 X113x2 中搜索 fe004000

  找到： PADCTRL_PIN_MUX_REG0 0xfe004000

  - 去 /mnt/fileroot/shengken.lin/workspace/sonos-sdk/bootloader/uboot-repo 下面 grep 找到： PADCTRL_PIN_MUX_REG

- 查找 PADCTRL_PIN_MUX_REG 这种寄存器描述文档： A5_system_Registers.docx

> D:\KendallFile\AllDoc\Meson\A5\appNote

  - 同样在 datasheet 中找 fe004000 对应的功能是： pad_ctrl




# 早期板子解决 adb 无法使用问题

> 打开 adb
 
 进入 kernel

```sh
mount -t configfs configfs /sys/kernel/config
mkdir /sys/kernel/config/usb_gadget/amlogic
echo 0x18D1 > /sys/kernel/config/usb_gadget/amlogic/idVendor
echo 0x4e26 > /sys/kernel/config/usb_gadget/amlogic/idProduct
mkdir /sys/kernel/config/usb_gadget/amlogic/strings/0x409
echo '0123456789ABCDEF' > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/serialnumber
echo amlogic > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/manufacturer
echo newman > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/product
mkdir /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1
mkdir /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409
echo adb > /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409/configuration
mkdir /sys/kernel/config/usb_gadget/amlogic/functions/ffs.adb
mkdir /dev/usb-ffs
mkdir /dev/usb-ffs/adb
mount -t functionfs adb /dev/usb-ffs/adb
stop adbd
ln -s /sys/kernel/config/usb_gadget/amlogic/functions/ffs.adb /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/ffs.adb
start adbd
/bin/sleep 2
echo ff400000.dwc2_a > /sys/kernel/config/usb_gadget/amlogic/UDC
```


# 板子挂载 U 盘

```sh
mkdir /mnt/usb
mount -t vfat /dev/sda1 /mnt/usb

umount /mnt/usb/
```

# av400 audio 工具

- 硬件连接

> D622  如果要使用 D603 功放需要更改

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/av400.5pr61x0fmdc0.webp)

## 修改 功放板 patch

https://scgit.amlogic.com/#/c/292999/

Change power amplifier driver board from D622 to D613

- 以 av400 为例修改提交

https://scgit.amlogic.com/#/c/292999/


## aspaly 常用命令

```
asplay  查看帮助信息
aspaly list  查看当前的输入源
asplay set-volume 60 设置音量
asplay get-volume 获取音量
asplay enable-input xx   切换输入源， xx 为实际的输入模式，比如 HDMI1
```

## 设置音量

```sh
set-ad82128-volume.sh 150

# 或者
amixer controls
amixer cget numid=1
amixer cset numid=1 150

# 测试音频
speaker-test -t sine -D hw:0,1
```

## aplay 播放

```sh
# 查看声卡设备
arecord -l

aplay -Dhw:0,1 /data/the-stars-48k-60s.wav

# 录音
arecord -Dhw:1,0 -c 1 -r 48000 -f S32_LE -t wav -d 20 /data/kernel54_20s.wav 
```


## av400 测试 uac 脚本

```sh
rmmod sdio_bt
rmmod vlsicomm

#1 config adb & uac2,

mount -t configfs configfs /sys/kernel/config
mkdir /sys/kernel/config/usb_gadget/amlogic
echo 0x18D1 > /sys/kernel/config/usb_gadget/amlogic/idVendor
echo 0x4e26 > /sys/kernel/config/usb_gadget/amlogic/idProduct
mkdir /sys/kernel/config/usb_gadget/amlogic/strings/0x409
echo '0123456789ABCDEF' > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/serialnumber
echo amlogic > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/manufacturer
echo korlan > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/product
mkdir -p  /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409

mkdir /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x401
echo "uac2" > /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x401/configuration
mkdir /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0
echo 0x3 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/c_chmask
echo 48000 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/c_srate
echo 4 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/c_ssize
echo 0x3  > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_chmask
echo 48000 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_srate
echo 4 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_ssize
ln -s /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0 /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/uac2.0

echo "config ADB"
echo adb > /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409/configuration
mkdir /sys/kernel/config/usb_gadget/amlogic/functions/ffs.adb
mkdir -p /dev/usb-ffs/adb
mount -t functionfs adb /dev/usb-ffs/adb
killall adbd  
ln -s /sys/kernel/config/usb_gadget/amlogic/functions/ffs.adb /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/ffs.adb
/usr/bin/adbd &

sleep 3

echo "" > /sys/kernel/config/usb_gadget/amlogic/UDC  
echo "fdd00000.crgudc2" > /sys/kernel/config/usb_gadget/amlogic/UDC 

arecord -l 
#2 arecord from uac sound card,
arecord -Dhw:1,0 -c 2 -r 48000 -f S32_LE -t wav -d 15 /data/test.wav 
arecord -Dhw:1,0 -c 2 -r 48000 -f S32_LE -t wav   | aplay  -Dhw:0,1

# aplay
amixer cset numid=1 180
aplay -Dhw:0,1 /data/test.wav 
```


### 修改 f_uac2 模式支持 window 播放

> 以 a5-av400 为例

```sh
#上面脚本只需要修改 0x18D2 即可
echo 0x18D2 > /sys/kernel/config/usb_gadget/amlogic/idVendor
```

[Dont't Merge][AV400]Change USB_DT_ENDPOINT and USB_DIR_IN for window uac

patch: https://scgit.amlogic.com/295197

# buildroot 修改 defconfig

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

# 查看音频 clk

measure-clk

- 挂载 debugfs

mount -t debugfs none /sys/kernel/debug

cat /sys/kernel/debug/clk/clk_summary | grep a5

- amlogic

cat   sys/kernel/debug/meson-clk-msr/measure_summary  | grep hifi_pll
<<<<<<< HEAD
cat   sys/kernel/debug/meson-clk-msr/measure_summary  | grep audio_
=======
cat   sys/kernel/debug/meson-clk-msr/measure_summary  |  grep pll
>>>>>>> 7415349f40fe679ff38a0399cba99618d532bf2c

- korlan

cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*

- AV400 播放音频查看 clk

将 dump_pcm_setting 中的 pr_debug 改成 pr_info

```c
static void dump_pcm_setting(struct pcm_setting *setting)
{
      if (!setting)
          return;
      pr_info("%s...(%pK)\n", __func__, setting); 
      pr_info("\tpcm_mode(%d)\n", setting->pcm_mode);
      pr_info("\tsysclk(%d)\n", setting->sysclk);
      pr_info("\tsysclk_bclk_ratio(%d)\n", setting->sysclk_bclk_ratio);
      pr_info("\tbclk(%d)\n", setting->bclk);
      pr_info("\tbclk_lrclk_ratio(%d)\n", setting->bclk_lrclk_ratio);
      pr_info("\tlrclk(%d)\n", setting->lrclk);
      pr_info("\ttx_mask(%#x)\n", setting->tx_mask);
      pr_info("\trx_mask(%#x)\n", setting->rx_mask);
      pr_info("\tslots(%d)\n", setting->slots);
      pr_info("\tslot_width(%d)\n", setting->slot_width);
      pr_info("\tlane_mask_in(%#x)\n", setting->lane_mask_in);
      pr_info("\tlane_mask_out(%#x)\n", setting->lane_mask_out);
}
```


# 查看 uboot 传递给 kernel 的参数

vim bootloader/uboot-repo/bl33/v2019$ ls include/env_default.h 

bootargs

对应的 config 在 bootloader/uboot-repo/bl33/v2019/board/amlogic/  

比如 bootloader/uboot-repo/bl33/v2019/board/amlogic/configs/a5_av400.h 

```sh
"storeargs="\
        "get_bootloaderversion;" \
        "setenv bootargs ${initargs} ${fs_type} otg_device=${otg_device} "\
                "logo=${display_layer},loaded,${fb_addr} vout=${outputmode},enable panel_type=${panel_type} "\
                "hdmitx=${cecconfig},${colorattribute} hdmimode=${hdmimode} "\
                "hdmichecksum=${hdmichecksum} dolby_vision_on=${dolby_vision_on} " \
                "hdr_policy=${hdr_policy} hdr_priority=${hdr_priority} "\
                "frac_rate_policy=${frac_rate_policy} hdmi_read_edid=${hdmi_read_edid} cvbsmode=${cvbsmode} "\
                "osd_reverse=${osd_reverse} video_reverse=${video_reverse} irq_check_en=${Irq_check_en} isr_check_en=${Irq_check_en} "\
                "androidboot.selinux=${EnableSelinux} androidboot.firstboot=${firstboot} jtag=${jtag}; "\                                                                                                                                           
        "setenv bootargs ${bootargs} androidboot.bootloader=${bootloader_version} androidboot.hardware=amlogic;"\
        "run cmdline_keys;"\
        "\0"\
```

# 应用层通过驱动给 kernel 传递参数

```c
static unsigned int uac_irq_cnt; 
module_param(uac_irq_cnt, uint, 0444); 
MODULE_PARM_DESC(uac_irq_cnt, "uac irq cnt");
```

cat /sys/module/u_audio/parameters/uac_irq_cnt

## AV400 buildroot 测试 UAC

https://scgit.amlogic.com/293851

## AV400 kernel-5.4 打开 UAC

https://scgit.amlogic.com/#/c/293855/



git add arch/arm64/boot/dts/amlogic/a5_a113x2_av400_1g_spk.dts
git add drivers/usb/gadget/function/u_audio.c
git add sound/soc/amlogic/auge/tdm.c
git add sound/soc/amlogic/auge/tdm_bridge.c