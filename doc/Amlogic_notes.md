
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
amixer cset numid=2 130   # 修改音量
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

### 查看依赖和编译器

```
 # 查看依赖的库
 readelf -d libOpenVX.so | grep NEEDED
 
 # 看GLIB版本信息
 strings libOpenVX.so | grep GLI
  # 看GCC版本信息
 strings libOpenVX.so | grep GCC
```

### 对比二进制文件


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
```

- 查看 追踪 工具

```sh
https://ui.perfetto.dev/
# 要chrome打开
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

-------

# ramdisk init 中增加打印 log

```
write /dev/kmsg "TEST : =============222  lsken00"
```


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


@ken@:/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/vendor/amlogic$ git log
commit c0ffe047fced044fdd9c818329a281c02fb12ade (HEAD, m/master, eureka/master)
Author: kenkangxgwe <kenkangxgwe@google.com>
Date:   Tue Nov 8 02:20:01 2022 -0800

    [korlan] Add audio buffer uevent path to start script
    
    Bug: b/257163271
    Test: None
    Change-Id: I01065c1dd4bf82672474bfd625f8167ef5c094dc
    Reviewed-on: https://eureka-internal-review.git.corp.google.com/c/vendor/amlogic/+/817751
    Reviewed-by: Yi Fan <yfa@google.com>
    Reviewed-by: Anoush Khazeni <akhazeni@google.com>
    Tested-by: Cast CQ <no-reply-cast-cq@google.com>