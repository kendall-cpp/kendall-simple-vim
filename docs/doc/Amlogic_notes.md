
# dump寄存器

## i2c寄存器

```sh
i2cdump -f -y 0x01 0x2d
```

## korlan tdm 寄存器

```sh
# 23 表示 dump 出多少个寄存器，后面cat 出来，用计算器查看对应二进制位
#### EE_AUDIO_CLK_TDMOUT_A_CTRL 0xfe330090
#### EE_AUDIO_CLK_TDMOUT_D_CTRL 0xfe3300ec

> 0xfe3300ec - 0xfe330090 = 92 / 4 = 23

echo 0xfe330090 23 > /sys/kernel/debug/aml_reg/dump
cat /sys/kernel/debug/aml_reg/dump > /data/EE_AUDIO_CLK_TDMOUT.txt

# A4 dunp 寄存器
echo 0xfe008100 5 > /sys/kernel/debug/aml_reg/pdump
cat /sys/kernel/debug/aml_reg/pdump
```

可以参考 A4 的代码实现

```c
// drivers/amlogic/reg_access/reg_access.c
static int __init aml_debug_init(void)
{
        static struct dentry *dir_aml_reg;

        if (IS_ENABLED(CONFIG_DEBUG_FS)) {
                dir_aml_reg = debugfs_create_dir("aml_reg", NULL);
                if (IS_ERR_OR_NULL(dir_aml_reg)) {
                        pr_warn("failed to create debugfs directory\n");
                        dir_aml_reg = NULL;
                        return -ENOMEM;
                }   
                debugfs_create_file("paddr", S_IFREG | 0440,
                                    dir_aml_reg, &paddr_dev, &paddr_file_ops);
                debugfs_create_file("pdump", S_IFREG | 0440, 
                                     dir_aml_reg, &pdump_dev, &pdump_file_ops);
                debugfs_create_file("vaddr", S_IFREG | 0440,
                                    dir_aml_reg, &vaddr_dev, &vaddr_file_ops);
                debugfs_create_file("vdump", S_IFREG | 0440,
                                    dir_aml_reg, &vdump_dev, &vdump_file_ops);
        }

        return 0;
}
```

如果没有 /sys/kernel/debug/aml_reg/dump 这文件夹，是因为 debugfs 没有 mount 起来

```
/ # mount -t debugfs none /sys/kernel/debug
/ # mount | grep debug 
none on /sys/kernel/debug type debugfs (rw,relatime)
```

## tdm_bridge dump dam 数据

> A5-file\av400\tdm_bridge_dump_dam_2_wavfile.patch 

使用说明见 patch 代码的注释

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

# uac 模式

对应代码路径： drivers/usb/gadget/function/f_uac2.c 

- USB_ENDPOINT_SYNC_ASYNC

- USB_ENDPOINT_SYNC_ADAPTIVE

- USB_ENDPOINT_SYNC_SYNC

![](https://jsd.cdn.zzko.cn/gh/kendall-cpp/blogPic@main/blog-01/usb_enopint_mode.1ln58gbfssv4.webp)

- av400 可以使用这个 patch 进行修改

workspace/A5-file/av400/f_uac2-mode-ubuntu-or-win.patch

# 打开 usb 以太网

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

```
/ # ifconfig -a
eth0      Link encap:Ethernet  HWaddr 00:E0:4C:68:02:9B  
          inet addr:10.28.39.205  Bcast:10.28.39.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:30 errors:0 dropped:0 overruns:0 frame:0
          TX packets:2 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:3102 (3.0 KiB)  TX bytes:684 (684.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

## adb connect

- 命令： `adb connect <ip>:5555`

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

# 关于寄存器一些操作

```c
printk("reg:0x%02x", addr);   // u16 addr 
```

## __iomem

__iomem是linux2.6.9内核中加入的特性。是用来个表示指针是指向一个I/O的内存空间。主要是为了驱动程序的通用性考虑。由于不同的CPU体系结构对I/O空间的表示可能不同。

当使用__iomem时，编译器会忽略对变量的检查（因为用的是void __iomem）。若要对它进行检查，当__iomem的指针和正常的指针混用时，就会发出一些警告。

## 内核虚拟地址转物理地址的函数

__va()：从物理地址转换为虚拟地址;

__pa()：从虚拟地址转换为物理地址;

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


hexdump -C system_1.bin -n 32  # 显示32个字节
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

korlan 中抓 trace 命令


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

#测试 nandread 的时间； mtd4 没有使用的的分区
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex 

# 等 5秒 按回车

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > /data/trace_01.txt
```


## nandwrite

需要找一个 write_test_file 文件，往没有使用的分区去写

busybox time nandwrite /dev/mtd/mtd4 -s -0 -p /data/write_test_file 


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

amixer cset numid=14 150
amixer cset numid=15 150
amixer cset numid=2 150
amixer cset numid=3 150
amixer cset numid=1 200

# 测试音频
speaker-test -t sine -D hw:0,1
```

## aplay 播放

```sh
# 查看声卡设备
arecord -l

# card 0 device 1
aplay -Dhw:0,1 /data/the-stars-48k-60s.wav

 aplay  -Dhw:1,0 -c 2 -r 48000 -f S32_LE sine_2ch.wav

# 录音
arecord -Dhw:1,0 -c 1 -r 48000 -f S32_LE -t wav -d 20 /data/kernel54_20s.wav 
```


# 配置 UAC

参考 google korlan

> vendor/amlogic/sprinkles/prebuilt/systemfs_overlay/bin/usb_device_config.sh

> 以 av400 为例，在启动的时候配置 UAC 和 adb
>
> usb_device_config.sh
> start_usb_gadget.sh

```sh
#1 config adb & uac2,

mount -t configfs configfs /sys/kernel/config
mkdir /sys/kernel/config/usb_gadget/amlogic
echo 0x18D1 > /sys/kernel/config/usb_gadget/amlogic/idVendor  # 如果 f_uac2 换成了兼容 window 的模式，就使用 0x18D2
echo 0x4e26 > /sys/kernel/config/usb_gadget/amlogic/idProduct
mkdir /sys/kernel/config/usb_gadget/amlogic/strings/0x409
echo '0123456789ABCDEF' > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/serialnumber
echo amlogic > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/manufacturer
echo korlan > /sys/kernel/config/usb_gadget/amlogic/strings/0x409/product
mkdir -p  /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x409

mkdir /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x401
echo "uac2" > /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/strings/0x401/configuration
mkdir /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0
echo 0x1 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/c_chmask  # korlan 使用的是单声道，使用 0x01
echo 48000 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/c_srate
echo 4 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/c_ssize
# Disable playback capability to host
echo 0x0  > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_chmask  # 单声道 0x01
echo 48000 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_srate  # rate = 48k 或者 96k
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

udc_dev=$(ls /sys/class/udc)
#if /bin/exists /sys/class/udc/$udc_dev; then #udc name is found here if enabled in kernel
    echo "" > /sys/kernel/config/usb_gadget/amlogic/UDC  
    echo "$udc_dev" > /sys/kernel/config/usb_gadget/amlogic/UDC 
    echo "USB gadget enabled"
#else
#   echo "Warning: can't start USB gadget mode, adb will not work"
#   return 1
#fi

# rmmod wifi ko
rmmod sdio_bt
rmmod vlsicomm

# mount debugfs
mount -t debugfs none /sys/kernel/debug           

arecord -l
```

### 配置uac选用哪个 声卡

- **配置uac选用哪个 声卡**, 修改脚本，output/target/etc

```
/etc/asound.conf 
```

### 音频测试

```sh
#2 arecord from uac sound card,
arecord -Dhw:1,0 -c 2 -r 48000 -f S32_LE -t wav -d 15 /data/test.wav 
# -c 2 是两个通道
arecord -Dhw:1,0 -c 2 -r 48000 -f S32_LE -t wav  | aplay  -Dhw:0,1

arecord -Dhw:1,0 -c 1 -r 48000 -f S32_LE -t wav  |  aplay  -Dhw:0,0 -c 1 -r 48000 -f S32_LE 

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

## AV400 buildroot 测试 UAC

https://scgit.amlogic.com/293851

## AV400 kernel-5.4 打开 UAC

https://scgit.amlogic.com/#/c/293855/



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


# 查看音频 clk

measure-clk

- 挂载 debugfs

mount -t debugfs none /sys/kernel/debug

cat /sys/kernel/debug/clk/clk_summary | grep a5

- amlogic

cat   sys/kernel/debug/meson-clk-msr/measure_summary  | grep hifi_pll
cat   sys/kernel/debug/meson-clk-msr/measure_summary  | grep audio_
cat   sys/kernel/debug/meson-clk-msr/measure_summary  |  grep pll

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


# korlan 中 HIFI 调试

TDMB-CLK 计算公式

$$Target \ frequency = 24MHz \times \frac{DPLL\_M + \frac{DIV\_FRAC}{2^{17}}}{DPLL\_M} \times \frac{1}{OD} $$

TDMB-CLK 使用 HIFI PLL 作为 source clock ,因此，DIV_FRAC 为 HIFI寄存器地址。

## 公式递推

默认值如下

- DPLL_M (ppm_con.M): 128
- DPLL_N : 1
- OD : 1

$Target \ frequency = 24MHz \times \frac{DPLL\_M + \frac{DIV_FRAC}{2^{17}}}{DPLL\_M} \times \frac{1}{OD} $

$Target \ frequency = 24MHz \times \frac{128 + \frac{DIV\_FRAC}{2^{17}}}{1} \times \frac{1}{1} $

$ppm = \frac{\frac{DIV\_FRAC}{2^{17}}}{M} $

$Target \ frequency = 24MHz \times \frac{M}{N} \times (1 + ppm)$

通过改变 DIV_FRAC 来调整 ppm 的大小

- ppm < 0 时， TDMB-CLK 读的 clk 变慢
- ppm > 0 时， TDMB-CLK 读的 clk 变快

ppm 取值范围： $-1 < ppm < 1$

## driver 中 cur_centi_ppm 背景

因为内核中不支持 float 类型，google 需要小数点后的两两个粒度的境地，如： 0.00000762939453125（$7.629*{10}^{-6}$), 调节粒度需要精确多到 7.62 ，就需要在 kernel 中放大 $10^2$ 数量级。

```c
cur_centi_ppm = ppm_con.cur_ppm * 100;  // 用于google的算法调试
```

### 关注的关键节点

 /sys/module/snd_soc/parameters/tdm_cached_data


- cur_centi_ppm： user space 条件的值 （DIV_FRAC）
- tdm_cached_data： 还在 DMA 中未被 TDMB FIFO 读的 data 长度，app 根据这个值来调节 cur_centi_ppm 。


cur_centi_ppm：ppm * 100

tdm_cached_data ：TDMB FIFO 已经从 DMA buffer 中读取的 uac 数据

tdm_irq_cnt : TDMB FIFO 读取 DMA buffer 的中断数

man_ppm
- 1： 应用层可以调节 ppm
- 0： 自动调节 ppm

start_playing_threshold : 默认值 10，表示刚开始播放时需要判断， tdm_cached_data 的数据 $>=10ms$ 的数据时 （$192 \times 10 \ bytes$）

> **yuegui 提供图片参考**

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/hifi_pll_1.59g82nsqnec0.webp)

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.482m5ahvino0.webp)

@![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/hifi_pll_3.7bhuayw3e4o0.webp)

# 使用 uac playback

在配置 UAC 时需要打开 playback 

```sh
# Disable playback capability to host
echo 0x1  > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_chmask
echo 48000 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_srate
echo 4 > /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0/p_ssize
ln -s /sys/kernel/config/usb_gadget/amlogic/functions/uac2.0 /sys/kernel/config/usb_gadget/amlogic/configs/amlogic.1/uac2.0
```

# crg 控制器


## 通知 tdm_bridge stop 

通知 tdm_bridge stop 只需要在 中断处理函数 crg_gadget_handle_interrup 中。有事件来时，也就是 CRG_U3DC_STATUS_EINT 这个状态寄存器发生变化，直接判断 crg_udc->connected == 0 ,就可以调用通知函数 do_usb_disconn_notifier。

```c
int crg_gadget_handle_interrupt(struct crg_gadget_dev *crg_udc)
{
  if (tmp_status & CRG_U3DC_STATUS_EINT) {
    int i;

    if (crg_udc->connected == 0)
      do_usb_disconn_notifier(USB_STATE_ATTACHED);

    reg_write(&uccr->status, CRG_U3DC_STATUS_EINT);
    /*process event rings*/
    for (i = 0; i < CRG_RING_NUM; i++)
      process_event_ring(crg_udc, i);
  }
}
```

## TRB

用来描述数据传输请求的数据结构。每个TRB包含了一个USB传输操作的详细信息，如传输方向、数据长度、数据缓冲区地址等

> **TD 由一个或多个传输请求块（TRB）组成**

除了 TD 的最后一个 TRB 之外的所有 TRB 中都设置了链标志。注意，TD 可能由单个 TRB 组成，不得设置链标志

> 参考 Corigine_USB31_DRD_Datasheet_v1.4   8.6.3TRB

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.34hn6sjq83o0.webp)

- Data Buffer Pointer 数据缓冲指针： 指向与此 TRB 关联的数据缓冲区的**起始地址**
- TRB Transfer Size TRB 传输大小： 数据缓冲区大小，字节
- TD  Size : 此字段表示在完成此TRB后，仍需要为当前TD传输多少个数据包。(**最大 31 个**)
  - 如果链位为 1，并且有剩余字节不能形成 MPS 包，则将剩余字节添加到相同 TD 的所有后续 trb 的大小中，以计算还剩下多少包。
  - 如果剩余的数据包超过 31 个，请将 TD 大小设置为 31 个
- Interrupt Target 中断目标 ： 此字段指示如果设备需要为此 TRB 生成传输事件，则要使用哪个事件环。
- Cycle bit (C) ： 此位用于标记传输环的队列指针。
- No Snoop (NS) ： 保留以备将来使用。
- Chain bit (CH) ： 通过软件设置为 1，将此TRB与环上的下一个 TRB 关联起来，因此它们属于同一 TD 。
- Interrupt on Completion (IOC)  完成时中断 ： 如果设置了该位，设备控制器应通过生成一个传输事件并在下一个中断阈值断言一个中断来通知软件该 TRB 的完成。
- AZP ： 附加零长度数据包。
  - 这个字段只能在 EP 出端点的 TD 的最后一个 TRB 中 断言。在所有其他情况下，它都应予以清除。
  - 此字段不得在零长度的 TD 中 断言。
  - 设备控制器完成当前 TD 传输后将再发送一个零长度数据包。
- Block Event Interrupt (BEI) 块事件中断（BEI） ： 如果设置了此位，则 IOC 生成的传输事件**不应**在下一个中断阈值断中断。
- TRB Type ： 此 TRB 的类型。

## Corigine USB Device DMA

Corigine USB  设备的 DMA 是 xHCI , 是一种类 DMA 他们有三个类型的环，一个环是一个包好 TRB 数据结构的循环队列

- 命令环：一个用于设备控制器 , 系统软件使用命令环向设备控制器发出命令。
- 事件环：用户返回命令控制的状态 和 传输的结果。，然后参数到系统软件。
- 传输环：每个端点或流 , 传输环用于在系统**内存缓冲区和设备端点之间移动数据**

### 传输环

> **系统软件  ---> 设备控制器**

软件使用一个传输环来为单个 USB 端点安排工作项目。传输环被组织为传输描述符（TD）数据结构的循环队列，其中每个传输描述符定义一个或多个数据缓冲区，用来缓存 USB 数据的传入和传输 。传输环被 xHC 视为只读环。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.37nyl8x1ukq0.webp)

USB 设备的每个 活动端点 或者 流 都有一个传输环，用于参数特定的 TRB 。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.4mn8bwtyis60.webp)

入队指针 = 出队指针 时，传输环为空 。

### 事件环

> **设备控制器  ---> 系统软件**

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.4k9gw62k7ts0.webp)

事件环 和 参数环 的区别是，事件环： **设备控制器是生产者，而系统软件是 trb 的消费者**，这与 传输环 相反

事件环消费周期状态 （CSS :  Consumer Cycle State）

如果事件环 trb 环 bit 不等于 CSS ，那么这就不是个有效事件，软件就会停止对这个事件处理。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.30gsxfu89aa0.webp)

在上图中请注意，除了 Multi-TRB TD 的最后一个 TRB 外，其余的TRB中都设置了链位（CH）。设备控制器将 Multi-TRB TD 中的TRB从出队列指针解析到出队列指针（图中从上到下），从内存中的单独缓冲区形成一个连接的数据缓冲区。如果传输环与 OUT 端点相关联，则连接的数据缓冲区将作为单次传输发送到 USB 设备。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.hy4y0ubr5qo.webp)

注意，“散点/收集”列表中的“ TRB 长度”字段没有设置约束。传统上，散点收集列表所指向的所有缓冲区的长度都必须是“页面大小”，除了第一个和最后一个缓冲区（如上面的例子所示）。设备控制器不需要此约束条件。TD 中由正常、数据阶段或 Isoc  TRB 指向的任何缓冲区都可以是大小在 0 到 64K 字节之间的任何大小。例如，如果操作系统将虚拟内存缓冲区转换为物理页面列表时，列表中的一些条目引用多个连续的页面，则 TRB 的灵活长度字段允许 1：1 映射，即多页列表条目不需要定义为多个页面大小的 TRB。

## 传输类型

```c
if (udc_req_ptr->trbs_needed)

// 接着根据 trb 的类型来进行入队
if (usb_endpoint_xfer_control(udc_ep_ptr->desc))  // 控制传输类型
if (usb_endpoint_xfer_isoc(udc_ep_ptr->desc))     // 等时传输类型
if (usb_endpoint_xfer_bulk(udc_ep_ptr->desc))     // 批量传输类型
```

- **等时传输 和 sof 包共同点**

> 手册： 8.3.8Handling Isochronous Transfers

isochronous transfers （`/aɪˈsɑːkrənəs/`） 和 USB 的 SOF 包之间有一个共同点，那就是它们都涉及到 USB 数据传输中的时间同步。在 USB 总线上，每个帧都被划分为若干微桢（microframe），每个微桢由一个开始帧(SOF)信号指示开始。这个信号的作用是在 USB 设备和主机之间提供一个公共的时间基准，以确保传输数据的同步性能。而 isochronous transfers 则需要根据这个时间基准来在规定时间内传输数据，从而实现实时性应用的要求，这也是两者之间的共同点。

> 所以如果传输的 isoc pkt ，那么这个时候应该加上 timestamp 也是合理的 ??

- 在 crg_udc_handle_event 函数中，会去判断 trb 的类型，如果是传输 TRB ，那么就会进行出队传输，这里里判断是否是 isoc pkt 获取时间戳。

判断是不是 isoc 包的函数 `usb_endpoint_xfer_isoc(udc_ep_ptr->desc`

<strong><font color="orange" size="4">
代码分析见 [Amlogic代码分析 - crg 控制器分析](doc/Amlogic代码分析?id=crg-控制器分析)
</font></strong>




-------------




----

## crg_udc 的连接状态

- crg_udc->connected == 0  断开连接
- crg_udc->connected == 1  连接上

crg 端口（crg port）发生变化 ，就会调用 crg_handle_port_status 进行端口处理，下面是测试插入和拔出 USB 时的函数调用。

> **拔出 USB 时**

```c
//crg port 状态发生改变 CRG_U3DC_PORTSC_PLC
lsken00 -- crg_handle_port_status --- 4134
//控制器停止
lsken00 crg_gadget_stop -- 3008 crg_udc->connected = 0
```

> **插入 USB 时**

```c
//crg port 状态发生改变 CRG_U3DC_PORTSC_PRC
lsken00 crg_handle_port_status -- 3994 crg_udc->connected = 1
lsken00 crg_handle_port_status -- 3994 crg_udc->connected = 1
lsken00 crg_gadget_handle_interrupt -- 4311 crg_udc->connected = 1
//没接触稳定，重新断开又连接，所以这个流程会出现多次
lsken00 crg_gadget_stop -- 3008 crg_udc->connected = 0	
lsken00 crg_handle_port_status -- 3994 crg_udc->connected = 1
lsken00 crg_handle_port_status -- 3994 crg_udc->connected = 1
lsken00 crg_gadget_handle_interrupt -- 4311 crg_udc->connected = 1
```

## crg 处理中断

在连接 USB 之后，只要有中断来就会调用中断处理函数 crg_gadget_handle_interrup , 在中断处理函数中， 会去判断 CRG_U3DC_STATUS_EINT 这个状态寄存器，只要有事件产生就会调用下面的代码，循环处理事件。

> 这时候 `crg_udc->device_state = USB_STATE_POWERED` , 也就是 2 , 代表是有线连接

```c
	if (tmp_status & CRG_U3DC_STATUS_EINT) {
		int i;

		reg_write(&uccr->status, CRG_U3DC_STATUS_EINT);

		printk("crg_udc->device_state = %d\n", crg_udc->device_state);   // 2

		/*process event rings*/
		for (i = 0; i < CRG_RING_NUM; i++)
			process_event_ring(crg_udc, i);
	}
```

## corigine usb 核心寄存器

```c
struct crg_uccr {
	u32 capability;	/*0x00*/  // 功能寄存器指定了主机控制器实现的只读限制、限制和功能。这些值被用作主机控制器 (xhci) 驱动程序的参数。
	u32 resv0[3];

	u32 config0;	/*0x10*/
	u32 config1;
	u32 resv1[2];

	u32 control;	/*0x20*/
	u32 status;
	u32 dcbaplo;
	u32 dcbaphi;
	u32 portsc;
	u32 u3portpmsc;
	u32 u2portpmsc;
	u32 u3portli;

	u32 doorbell;	/*0x40*/
	u32 mfindex;
	u32 speed_select;
	u32 resv3[5];

	u32 ep_enable;	/*0x60*/
	u32 ep_running;
	u32 resv4[2];

	u32 cmd_param0;	/*0x70*/
	u32 cmd_param1;
	u32 cmd_control;
	u32 resv5[1];

	u32 odb_capability;	/*0x80*/
	u32 resv6[3];
	u32 odb_config[8];

	u32 debug0;	/*0xB0*/
};
```

- Capability Registers : 功能寄存器指定了主机控制器实现的只读限制、限制和功能。这些值被用作主机控制器 (xhci) 驱动程序的参数。

-  Runtime and Operational Registers : 指定了主机控制器的配置和运行时可修改的状态，并被系统软件用于控制和监控主机控制器的运行状态。这些寄存器被划分为在运行时大量访问的，以及仅在初始化时或在运行时少量访问的，以便更好地支持 xHCI 的虚拟化。

- xHCI Extended Capabilities : 指定了 xHCI 实现的可选特性，也就是扩展能力。

- Doorbell Array : 是一个多达 256 个门铃寄存器的阵列，它支持 255 个 USB 设备或集线器。每个门钟寄存器都为系统软件提供了一种机制，如果 xHC 有插槽或与端点相关的工作要执行，则可以通知 xHC。门铃寄存器中的ADB 目标字段是用一个值来标识“按”门铃的原因的。门铃寄存器 0 被分配给主机控制器，用于命令环管理。

- Controller Save State (CSS)

- Connect Status Change (CSC) : 此标志表示在端口的当前连接状态（CSS）或冷连接状态（CAS）位中发生了更改



### CRG USB3.1 接口

#### Master interface(AXI)

> USB3.1 Controller use AXI master to fetch TRB and data from system memory and EBC data buffer. And use this interface to write events to event ring.

USB3.1控制器使用 AXI 主服务器从系统内存和 EBC 数据缓冲区获取 TRB 和数据。并使用此接口将事件写入事件环。

#### Slave interface(AXI / AHB / APB)

> CPU use slave interface to access the registers in USB3.1 Device Controller, including interrupt handling and Device Controller configuration, Corigine USB3.1 IP support AXI, AHB and APB for slave interface

CPU 使用从接口访问 USB3.1 设备控制器中的寄存器，包括中断处理和设备控制器配置，源 USB3.1 IP 支持 AXI，AHB 和 APB 从接口

#### Interrupt interface(Legacy/MSI)

> USB3.1 Controller use this interface to inform CPU there is event to handle, System SW should read out and handle all events in event ring, SW should clear the interrupt by writing interrupt control register, Corigine USB3.1 IP support both legacy interrupt and MSI interrupt.

USB3.1 控制器使用此接口通知 CPU 有事件要处理，系统软件应读出并处理事件环中的所有事件，软件应通过写入中断控制寄存器清除中断，Corigine USB3.1 IP 支持遗留中断和 MSI 中断。

#### USB3.1 PHY interface(PIPE3)

传输数据到 PHY 接口

#### USB2.0 PHY interface(UTMI+/ULPI)

#### Top level full signal list



## process_event_ring

```c
// 8.7.23  Interrupt Management Register (IMAN)
// 8.7.24  Interrupter Moderation Register (IMOD)
struct crg_uicr {               
        u32 iman;   // Interrupt Management Register  中断寄存器
        u32 imod;   // Interrupter Moderation Register  中断器审核寄存器（IMOD）
        u32 erstsz; //事件环段表大小寄存器
        u32 resv0;
        //事件环脱队列指针寄存器 (ERDP)
        u32 erstbalo; /*0x10*/
        u32 erstbahi;
        // 事件环脱队列指针寄存器 (ERDP)
        u32 erdplo;
        u32 erdphi;
};
```

```c
int process_event_ring(struct crg_gadget_dev *crg_udc, int index) {
  // 拿到这个事件环的 一个事件
  udc_event = &crg_udc->udc_event[index];

  // 循环这个事件环的 trb 包
  while (udc_event->evt_dq_pt) { 
    ret = crg_udc_handle_event(crg_udc, event); // 处理这个事件的 trb

    // 如果是 链接 TRB （事件环的最后一个）
    if (event == udc_event->evt_seg0_last_trb) {}
      //改变消费周期状态
      udc_event->CCS = udc_event->CCS ? 0 : 1 // Consumer Cycle State 消费周期状态
      udc_event->evt_dq_pt = udc_event->event_ring.vaddr;
    } else {
      udc_event->evt_dq_pt++;   // 处理下一个trb
    }
  }
}

int crg_udc_handle_event(struct crg_gadget_dev *crg_udc,
			struct event_trb_s *event)
{
  int ret;

  switch (GETF(EVE_TRB_TYPE, event->dw3)) {
  case TRB_TYPE_EVT_PORT_STATUS_CHANGE:  // Port Status Change Event TRB
      if (crg_udc->device_state == USB_STATE_RECONNECTING) {
        crg_udc->portsc_on_reconnecting = 1;
        break;
      }
      /* 1.端口重置 2.端口连接更改 3.端口链接更改 */
      ret = crg_handle_port_status(crg_udc);  //处理端口状态变化
      break;
  case TRB_TYPE_EVT_TRANSFER: // 传输类型

    crg_handle_xfer_event(crg_udc, event);  // 处理传输的包
    break;
  case TRB_TYPE_EVT_SETUP_PKT:  // 安装类型的包
    {
        // 将这个包入队
        queue_setup_pkt(crg_udc, setup_pkt, setup_tag);
        break;
      }
      // 开始执行安装处理程序
      crg_handle_setup_pkt(crg_udc, setup_pkt, setup_tag);

      break;
    }
  }
}
```

> 对应 8.6.3.4 TRB Type Encoding


### crg_handle_xfer_event

> 传输包处理

```c
int crg_handle_xfer_event(struct crg_gadget_dev *crg_udc,
			struct event_trb_s *event)
{
  // isochronous trb timestamp  在这里添加时间戳
	if (usb_endpoint_xfer_isoc(udc_ep_ptr->desc))
		crg_isoc_timer_hit();

	comp_code = GETF(EVE_TRB_COMPL_CODE, event->dw2);
	switch (comp_code) {
    case CMPL_CODE_SUCCESS:
    {
      handle_cmpl_code_success(crg_udc, event, udc_ep_ptr);
      trbs_dequeued = true;
    }
    case CMPL_CODE_SHORT_PKT:
    {
      if (usb_endpoint_dir_out(udc_ep_ptr->desc)) {
        if (udc_req_ptr->usb_req.actual != 512 && udc_req_ptr->usb_req.actual != 31) {
          trb_pt = (u64)event->dw0 +
            ((u64)(event->dw1) << 32);
          p_trb = tran_trb_dma_to_virt(udc_ep_ptr, trb_pt);
        }
        req_done(udc_ep_ptr, udc_req_ptr, 0);
      }
      //将出队指针推进到下一个 TD
      advance_dequeue_pt(udc_ep_ptr);
    }
    case CMPL_CODE_PROTOCOL_STALL:
    {
      udc_req_ptr = list_entry(udc_ep_ptr->queue.next,
            struct crg_udc_request, queue);
      req_done(udc_ep_ptr, udc_req_ptr, -EINVAL);
      trbs_dequeued = true;
      crg_udc->setup_status = WAIT_FOR_SETUP;
      advance_dequeue_pt(udc_ep_ptr);
      break;
    }
    case CMPL_CODE_SETUP_TAG_MISMATCH:
    {
      /* skip seqnum err event until last one arrives. */
      if (udc_ep_ptr->deq_pt == udc_ep_ptr->enq_pt) {
        udc_req_ptr = list_entry(udc_ep_ptr->queue.next,
            struct crg_udc_request,
            queue);

        if (udc_req_ptr)
          req_done(udc_ep_ptr, udc_req_ptr, -EINVAL);

        /* drop all the queued setup packet, only
        * process the latest one.
        */
        crg_udc->setup_status = WAIT_FOR_SETUP;
        if (enq_idx) {
          crg_setup_pkt =
            &crg_udc->ctrl_req_queue[enq_idx - 1];
          setup_pkt = &crg_setup_pkt->usbctrlreq;
          setup_tag = crg_setup_pkt->setup_tag;
          crg_handle_setup_pkt(crg_udc, setup_pkt,
                setup_tag);
          /* flash the queue after the latest
          * setup pkt got handled..
          */
          memset(crg_udc->ctrl_req_queue, 0,
            sizeof(struct crg_setup_packet)
            * CTRL_REQ_QUEUE_DEPTH);
          crg_udc->ctrl_req_enq_idx = 0;
        }
      } else {
      }
      crg_udc->setup_tag_mismatch_found = 1;
      break;
    }
  }
}
```

- Completion Code （comp_code）: 此字段表示所指向的 TRB 的完成状态。对于在进行到下一个 TD 时设置了 IOC 位的 TRB 生成的传输事件，应忽略该字段。

```c
enum TRB_CMPL_CODES_E {
	CMPL_CODE_INVALID       = 0,
	CMPL_CODE_SUCCESS,
	CMPL_CODE_DATA_BUFFER_ERR,
	CMPL_CODE_BABBLE_DETECTED_ERR,
	CMPL_CODE_USB_TRANS_ERR,
	CMPL_CODE_TRB_ERR,  /*5*/
	CMPL_CODE_TRB_STALL,
	CMPL_CODE_INVALID_STREAM_TYPE_ERR = 10,
	CMPL_CODE_SHORT_PKT = 13,
	CMPL_CODE_RING_UNDERRUN,
	CMPL_CODE_RING_OVERRUN, /*15*/
	CMPL_CODE_EVENT_RING_FULL_ERR = 21,
	CMPL_CODE_STOPPED = 26,
	CMPL_CODE_STOPPED_LENGTH_INVALID = 27,
	CMPL_CODE_ISOCH_BUFFER_OVERRUN = 31,
	/*192-224 vendor defined error*/
	CMPL_CODE_PROTOCOL_STALL = 192,
	CMPL_CODE_SETUP_TAG_MISMATCH = 193,
	CMPL_CODE_HALTED = 194,
	CMPL_CODE_HALTED_LENGTH_INVALID = 195,
	CMPL_CODE_DISABLED = 196,
	CMPL_CODE_DISABLED_LENGTH_INVALID = 197,
};
```

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.1g7hwqd3alnk.webp)

- Short Packet

  - 这表明主机发送的数据小于当前 TD 的大小。
  - TRB传输长度字段表示在指向的TRB中尚未传输多少字节
  - 如果同一TD有更多的 trb，设备将自动前进到下一个 TD。转会事件将生成的 TRB 与 IOC，同时推进到下一个 TD


### crg_handle_port_status

处理端口状态变化

```c
int crg_handle_port_status(struct crg_gadget_dev *crg_udc)
{
  struct crg_uccr *uccr = crg_udc->uccr;
  portsc_val = reg_read(&uccr->portsc);  // Port Status and Control Register (PORTSC)
}
```

- Port Status and Control Register (PORTSC) 【代码中使用的宏： CRG_U3DC_PORTSC_PP 】

  - 由主机控制器的特定实例化实现的端口寄存器数被记录在 HCSPARAMS1 寄存器中，即参数 MAX_PORTS

  - 仅在冷复位或响应主机控制器复位（HCRST）时，由平台硬件进行复位。

  - 除非确认端口电源（PP）=（1），否则软件不能改变端口的状态，而不管端口功率控制（PPC）功能

  - 如果一个端口已被分配给调试功能，则该端口不得报告已连接的设备（即中国化学会=“0”），并在端口电源标志为“1”时启用

## crg_udc_build_td

- 先判断是否需要完成上一次未完成的传输

```c
if (udc_req_ptr->trbs_needed)

// 接着根据 trb 的类型来进行入队
if (usb_endpoint_xfer_control(udc_ep_ptr->desc))  // 控制传输类型
if (usb_endpoint_xfer_isoc(udc_ep_ptr->desc))     // 等时传输类型
if (usb_endpoint_xfer_bulk(udc_ep_ptr->desc))     // 批量传输类型
```

- 等时传输 和 sof 包共同点

> 手册： 8.3.8Handling Isochronous Transfers

isochronous transfers （`/aɪˈsɑːkrənəs/`） 和 USB 的 SOF 包之间有一个共同点，那就是它们都涉及到 USB 数据传输中的时间同步。在 USB 总线上，每个帧都被划分为若干微桢（microframe），每个微桢由一个开始帧(SOF)信号指示开始。这个信号的作用是在 USB 设备和主机之间提供一个公共的时间基准，以确保传输数据的同步性能。而 isochronous transfers 则需要根据这个时间基准来在规定时间内传输数据，从而实现实时性应用的要求，这也是两者之间的共同点。

> 所以如果传输的 isoc pkt ，那么这个时候应该加上 timestamp 也是合理的 ??

- 在 crg_udc_handle_event 函数中，会去判断 trb 的类型，如果是传输 TRB ，那么就会进行出队传输，这里里判断是否是 isoc pkt 获取时间戳。

判断是不是 isoc 包的函数 `usb_endpoint_xfer_isoc(udc_ep_ptr->desc`

- 如果是 入队数据包 （TRB_TYPE_EVT_SETUP_PKT） ， 那么就进行入队操作

```c
int process_event_ring(struct crg_gadget_dev *crg_udc, int index) 
{
  if (event == udc_event->evt_seg0_last_trb) {  // 一个事件环的最后一个数据包（链接 trb）
  else 
  udc_event->evt_dq_pt++;  // 下一个trb
}
```
