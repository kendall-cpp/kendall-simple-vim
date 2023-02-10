- [TASK：测试 i2s clock](#task测试-i2s-clock)
  - [在 Ubuntu 下测试](#在-ubuntu-下测试)
  - [最终提交1](#最终提交1)
  - [最终提交2](#最终提交2)
  - [复现 dock-test-tool 测试问题](#复现-dock-test-tool-测试问题)
- [添加 fct-korlan 实现联网](#添加-fct-korlan-实现联网)
  - [kernel 打开个 CONFIG\_USB\_RTL8152](#kernel-打开个-config_usb_rtl8152)
  - [fct-kolran 设置 IP](#fct-kolran-设置-ip)
  - [设置开机自动获取 ip](#设置开机自动获取-ip)
  - [adb调试ipv6](#adb调试ipv6)
  - [开启 ipv6 和 RTL8152](#开启-ipv6-和-rtl8152)
  - [重新编译成 ko 文件，并加载到init.rc](#重新编译成-ko-文件并加载到initrc)
    - [提交](#提交)
- [熟悉和测试 korlan5.15](#熟悉和测试-korlan515)
- [flush-ubifs\_7\_0(adb push ota.zip) 线程 CPU 过高导致 tdm underrun](#flush-ubifs_7_0adb-push-otazip-线程-cpu-过高导致-tdm-underrun)
  - [复现问题](#复现问题)
    - [perf 工具使用](#perf-工具使用)
  - [工作流程](#工作流程)
  - [isp 内部优化 usleep](#isp-内部优化-usleep)
  - [yi-u\_audio-log\_uac\_timing-tdm-cpu](#yi-u_audio-log_uac_timing-tdm-cpu)
  - [nandread去读卡](#nandread去读卡)
    - [yuegui 飞书记录](#yuegui-飞书记录)
  - [测试 nandread](#测试-nandread)
  - [单独编译 nandread](#单独编译-nandread)
  - [打印时间](#打印时间)
    - [4.19](#419)
    - [5.15 默认](#515-默认)
    - [5.15 修改](#515-修改)
  - [总结](#总结)
    - [总结回复 google](#总结回复-google)
- [kernel 裁剪](#kernel-裁剪)
  - [kernel 裁剪优化记录](#kernel-裁剪优化记录)
- [Korlan 开机声卡顿问题](#korlan-开机声卡顿问题)
- [tdm\_bridge 优化](#tdm_bridge-优化)
- [开启并制作 erofs 文件系统](#开启并制作-erofs-文件系统)
  - [下载和编译 erofs-utils](#下载和编译-erofs-utils)
  - [压缩到 image](#压缩到-image)
  - [学习给korlan增加一个分区](#学习给korlan增加一个分区)
  - [读取分区表](#读取分区表)
  - [将自己制作的文件系统挂载起来](#将自己制作的文件系统挂载起来)
    - [解决分区不足和不支持 lz4 压缩问题](#解决分区不足和不支持-lz4-压缩问题)
  - [解决 Permission denied 问题](#解决-permission-denied-问题)
  - [iozone 测试](#iozone-测试)
- [kernel 4.19 功能迁移到 kernel 5.4](#kernel-419-功能迁移到-kernel-54)
  - [修改 功放板 patch](#修改-功放板-patch)
  - [打开 UAC](#打开-uac)
>>>>>>> 4e70d81561321021de26f97724a2502c0abef3a3


-------------




## TASK：测试 i2s clock

> https://partnerissuetracker.corp.google.com/issues/243087651

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247301

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247425

```sh
dmesg  -n 8

cat /sys/kernel/debug/tas5805_debug/seq_timestamp

echo 0 > /sys/kernel/debug/tas5805_debug/seq_timestamp   关闭

echo 1 > /sys/kernel/debug/tas5805_debug/seq_timestamp   打开

cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*

amixer cget numid=2 

amixer cset numid=2 150   # 修改音量

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav 

```


- dump 寄存器

```
i2cdump -f -y 0x01 0x2d
```

### 在 Ubuntu 下测试

进入 codecs

adb shell


### 最终提交1

git add sound/soc/codecs/tas5825m.c

git commit -s --no-verify    // git commit --amend  --no-verify     第二次 加changeID

```sh
[tas5805] Enable/disable i2s clock when power on/off codec

Bug:b/236912216
Test: build ok

Signed-off-by: Shengken Lin <shengken.lin@amlogic.corp-partner.google.com>
Change-Id: Iad9dba635ddd890457398c6bed8cba324feb80f0
```

git push eureka-partner HEAD:refs/for/korlan-master


https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247301



### 最终提交2

git add 

git commit -s --no-verify    // git commit --amend  --no-verify     第二次 加changeID



```sh
    [Dont't merge] Test enable/disable i2s clock when power on/off codec
    
    Bug:b/236912216
    Test:
    case 1:power off codec(disable i2s clock)
    / # echo 0 > /sys/kernel/debug/tas5805_debug/seq_timestamp
    / # cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*
     tdmout_b_sclk                 0    +/-3125Hz
     tdmout_a_sclk                 0    +/-3125Hz
     tdmin_lb_sclk                 0    +/-3125Hz
     tdmin_b_sclk                  0    +/-3125Hz
     tdmin_a_sclk                  0    +/-3125Hz
     tdmin_vad_clk                 0    +/-3125Hz
    
    case 2:power on codec(enable i2s clock)
    / # echo 1 > /sys/kernel/debug/tas5805_debug/seq_timestamp
    / # cat /sys/kernel/debug/aml_clkmsr/clkmsr | grep tdm*
     tdmout_b_sclk           3067188    +/-3125Hz
     tdmout_a_sclk                 0    +/-3125Hz
     tdmin_lb_sclk                 0    +/-3125Hz
     tdmin_b_sclk            3068750    +/-3125Hz
     tdmin_a_sclk                  0    +/-3125Hz
     tdmin_vad_clk                 0    +/-3125Hz
    
    Signed-off-by: Shengken Lin <shengken.lin@amlogic.corp-partner.google.com>
    Change-Id: I8c5fc26d97b1643f0074e8823cae98fc42ba9e70
```

```c
static struct tas5825m_priv *write_priv; 
write_priv = priv; 


  static ssize_t ta5805_i2s_write(struct file *filp, const char __user *buf, size_t count, loff_t *off)                                                                            
  {
          char val[10];
          int tmp_val = 0; 
   
          if (count > 10)
                  return -1;
   
          if(copy_from_user(val, buf, count))
                  return -EFAULT;
          else {
                  sscanf(val, "%d", &tmp_val);
                  if (tmp_val == 1)
                          tas5805m_power_on(write_priv);
                  else if (tmp_val == 0)
                          tas5805m_power_off(write_priv);
                  else 
                          pr_err("echo 1 or 0 to enable i2c clock or disable i2c clock");
          }    
          return count;
  }


  struct file_operations ta5805_timestamp_file_ops = {
    .open   = simple_open,
    .read = ta5805_timestamp_read,
    .write = ta5805_i2s_write,
  };  
```

git push eureka-partner HEAD:refs/for/korlan-master


https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/247425


-------------------



### 复现 dock-test-tool 测试问题

https://partnerissuetracker.corp.google.com/issues/245839768


- 下载最新 korlan-ota 烧录


- 在 ubuntu 上进行测试

```sh
$ dd if=/dev/urandom bs=1048576 count=35 of=fake-ota.zip
$ dock-test-tool nest-ota-push --block-size=524288 ./fake-ota.zip   # 异常

$ dock-test-tool nest-ota-push  ./fake-ota.zip   # 正常
```

- 调试和文档

https://partnerissuetracker.corp.google.com/issues/230885799

https://docs.google.com/document/d/16La7BkKlu0sbsQgruMoemk4QlBBqF8B7xHdMM74hXLk/edit?usp=sharing


## 添加 fct-korlan 实现联网

> https://partnerissuetracker.corp.google.com/issues/247080714


###  kernel 打开个 CONFIG_USB_RTL8152

```sh
arch/arm64/configs/korlan-p2_defconfig

CONFIG_USB_RTL8152=y
```

### fct-kolran 设置 IP
  
- comment

Hi Kim,

You need to push the dhcpcd_service.sh in the attachment into the corresponding path of korlan fct (my path: /sbin/dhcpcd_service.sh),

- Modify the korlan FCT init.rc file through the following patch

```
--- a/korlan/factory/init.rc
+++ b/korlan/factory/init.rc
+
+service dhcpcd /bin/sh /sbin/dhcpcd_service.sh                                       
+    class service
+    user root
```

- Enable eth0 and get ip by the following methods

```
/ # echo 1 > /sys/kernel/debug/usb_mode/mode
/ # fts -s enable_ethernet dhcp
/ # fts -g "enable_ethernet"
dhcp

/ # start dynamic_ip_eth0
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

https://partnerissuetracker.corp.google.com/issues/247080714


----



### 设置开机自动获取 ip

```
on post-fd
        exec /bin/sh -c "echo 1 > /sys/kernel/debug/usb_mode/mode"

# start dhcpcd                           
start dhcpcd
```


### adb调试ipv6

- chrome 单独编译一个模块

mma PARTNER_BUILD=true

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/adb

mma PARTNER_BUILD=true

# test
echo 0 > /sys/kernel/debug/usb_mode/mode
```

- 修改成 ipv4 调试 ipv6

```sh
# libcutils/socket_inaddr_any_server_unix.cpp
```

### 开启 ipv6 和 RTL8152


### 重新编译成 ko 文件，并加载到init.rc

拷贝到 ramdisk sbin 目录下

```sh
cp kernel/net/ipv6/ipv6.ko  /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk/korlan/fct_ramdisk/sbin

# 只需要这个 ko

insmod /sbin/ipv6.ko
```

#### 提交

```
[Korlan] Build IPV6 to ko and enable RTL8152

fct-korlan "adb connect <ip>:5555" requires ipv6 and usb ethernet

Bug: 247080714
Test:
/ # insmod ipv6.ko
/ # start dhcpcd
/ # start adbd
/ # netstat 
Proto Recv-Q Send-Q Local Address          Foreign Address        State
 tcp       0      0 127.0.0.1:5037         0.0.0.0:*              LISTEN
 udp       0      0 0.0.0.0:68             0.0.0.0:*              CLOSE
tcp6       0      0 :::5555                :::*                   LISTEN

```

- comment

https://partnerissuetracker.corp.google.com/issues/247080714

Hi Jason,
I've updated ipv6 to minimal ko, please check this cl.

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/260551
```

- git push

```sh
git push eureka-partner HEAD:refs/for/korlan-master

# 需要关注
 https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/260551
 commit id: 7ef11940e2f980a3e10243fce1cdb87cd80cf1d6
```

## 熟悉和测试 korlan5.15

5.15 gerrit： https://eureka-partner-review.googlesource.com/q/project:amlogic%252Fkernel+branch:korlan-master-5.15

4.19 --> 5.15 patch 汇总

https://docs.google.com/spreadsheets/d/13U6Hkhk2m3KIBXcxSEuuZGy0tE6gJjGxyCAuNv9j4BE/edit#gid=0


编译 kernel5.15 ota

```sh
    rm out/target/product/korlan/recovery/root -rf
    rm out/target/product/korlan/root -rf
    rm out/target/product/korlan/obj/PACKAGING -rf
    PARTNER_BUILD=true BOARD_NAME=korlan-b1 make -j30 otapackage KERNEL_VERSION=5.15
```

```
cherry-pick kernel5.15 all cl  直接 git  checkout
		korlan-master-5.15,
			https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/261786
		korlan-master-5.15-drivers,
			https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/261466	
		vendor/amlogic,
			https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/257546
	1) build amlogic_sdk, 
		./sdk/build_scripts/build_all.sh /path/chrome/ sprinkles --kernel=5.15
```


----

## flush-ubifs_7_0(adb push ota.zip) 线程 CPU 过高导致 tdm underrun 

> 用 kernel 4.19 来解决

> https://partnerissuetracker.corp.google.com/issues/241159916


### 复现问题

```sh
Z:\workspace\google_source\eureka-v2\chrome\out\target\product\korlan> adb push .\korlan-ota-eng.shengken.lin.zip /data

# 在push期间执行下面命令检测
top -m 5 -t
```

#### perf 工具使用

```sh
# 编译
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/korlan-sdk/kernel$ ./build_perf.sh korlan ../../chrome
```

如果想在板子上能使用 perf ,可以直接打上这个  patch  开启相应的 config 即可。

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/239808

```sh
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/239808
kernel$ git fetch https://eureka-partner.googlesource.com/amlogic/kernel refs/changes/08/239808/10 && git cherry-pick FETCH_HEAD
# commit id: 8fb66d4b95ea24013c73470ae004f111158f6ca3


# korlan-sdk/kerne
bash build_perf.sh korlan

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

打完 patch 的 commit id： d7c8eae34cdc182639dd6101f5eadbcbb787ff10

### 工作流程

往 tdm 中写数据时，出现了 underrun ，就是写 太慢了，读快了，通过轮训的方式去读取会出现卡顿问题

USB 写数据 （先写到 ddr，再 sync 到 falsh，在 sync 的时候会占用 CPU ） --> tdm_bridge --> codec -- > Speaker  播放


```sh
vim sound/soc/amlogic/auge/tdm_bridge.c 

# 往 tdm_bridge 写数据函数
int aml_tdm_br_write_data(void *data, unsigned int len)

# 调用
drivers/usb/gadget/function/u_audio.c
```


### isp 内部优化 usleep

```sh
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/244846
# git fetch https://eureka-partner.googlesource.com/amlogic/kernel refs/changes/46/244846/3 && git cherry-pick FETCH_HEAD
# 26da25f44a02588c0525d3b1e6d1dc8f5cb72856
```

### yi-u_audio-log_uac_timing-tdm-cpu

```sh
# 第一个patch comment #8
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/246965
commit ID: 182c1d24317734067caa440efd0df4f879c5ea2f

 
# 第二个patch   comment #21
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/250805
git fetch https://eureka-partner.googlesource.com/amlogic/kernel refs/changes/05/250805/4 && git cherry-pick FETCH_HEAD
commit ID: c108b9c0c97bb5af5dfcaa5ab994a9b1d9ac2a00
```

测试 patch： tmp_patch/u_audio_stash_google_underrun.patch

---

### nandread去读卡

> https://jira.amlogic.com/browse/GH-3176

####  yuegui 飞书记录

```
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

busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex &

等 五秒 按回车

sleep 5

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > /data/trace_01.txt
```

- 查看 trace.txt 工具

```sh
https://ui.perfetto.dev/
# 要chrome打开
```


- 打开 trace patch

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/239808

```c
git cherry-pick --continue  // 1. 解决完冲突以后，继续下一个 cherry-pick
git cherry-pick --abort   // 2. 如果不想解决冲突，要放弃合并，用此命令回到操作以前
git cherry-pick --quit   // 3. 不想解决冲突，放弃合并，且保持现有情况，不回到操作以前
```

### 测试 nandread

> https://partnerissuetracker.corp.google.com/issues/258016139

> https://jira.amlogic.com/browse/GH-3176

```
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex & 
/data/iostat -d 1 > /data/5.15-iostat-test2.log

/data/iostat  -d 1 > /data/5.15-iostat-test3.log &
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex


/data/iostat  -d 1 > /data/5.15-iostat-1min.log
/data/iostat  -d 1 > /data/4.19-iostat-1min.log
```

- 关掉 iot_dock_usb 查看 IO

```sh
修改 vendor/amlogic/korlan/init.rc

 /data/iotop  -m 5 -s read -n 30
```

- jiucheng.xu 测试 nandrad 读卡

```sh

echo > /sys/kernel/debug/tracing/trace
echo 40960 > /sys/kernel/debug/tracing/buffer_size_kb
echo 'p:my_kprobe __spi_pump_messages' >> /sys/kernel/debug/tracing/kprobe_events
echo 1 > /sys/kernel/debug/tracing/events/kprobes/my_kprobe/enable
echo 1 > /sys/kernel/debug/tracing/options/stacktrace  
echo 1 > /sys/kernel/debug/tracing/tracing_on
# 测试程序 &

busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex &
# sleep 2
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > /data/b.txt
```

- 关掉 cgroup-metricsd  & standalone_mojo & process_monitor 

- 开机执行：

```sh
/data/iotop -m 5 -s read -n 20 > /data/a.txt
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
```

```sh
/data/iotop -m 5 -s read -n 20 > /data/a.txt &
/data/iostat 1 > /data/b.txt &
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
killall iostat
```

- 測試

```
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

echo 1 > /sys/kernel/debug/tracing/tracing_on    # 打开trace
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
# sleep 一会
echo 0 > /sys/kernel/debug/tracing/tracing_on
dd if=/sys/kernel/debug/tracing/trace of=/tmp/trace.bringup.bin bs=1M
```

```
strace -e read -o /data/a5.15.txt nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex

strace -e read -o /data/a4.19.txt -T nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
strace -e read -o /data/a5.15.txt -T nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
```

- 重启执行测试

busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex


### 单独编译 nandread

```sh
source build/envsetup.sh 
lunch 
16 Korlan-eng
cd chrome/system/core/toolbox
lrwxrwxrwx 1 shengken.lin szsoftware 7 Dec  5 19:11 ./out/target/product/korlan/recovery/root/bin/nandread -> toolbox
```

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/toolbox
 mma PARTNER_BUILD=true

./out/target/product/korlan/recovery/root/bin/nandread
```



### 打印时间

```
main.c   start_kernel() --- arch_call_rest_init() -- rest_init() -- kernel_thread(kernel_init, NULL, CLONE_FS); --   kernel_init_freeable  -- prepare_namespace  -- mount_root
```

- 修改 init.rc

```sh
write /dev/kmsg "TEST : nandread  lsken00"
exec /sbin/busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
```


- 在 kernel 中修改

```sh
diff --git a/drivers/spi/spi.c b/drivers/spi/spi.c
index 49f592e433a8..5de26f14c1ec 100644
--- a/drivers/spi/spi.c
+++ b/drivers/spi/spi.c
@@ -346,6 +346,8 @@ static int spi_drv_probe(struct device *dev)
        struct spi_device               *spi = to_spi_device(dev);
        int ret;
 
+        printk("-- %s -- %d -- lsken00\n",__func__, __LINE__);
+
        ret = of_clk_set_defaults(dev->of_node, false);
        if (ret)
                return ret;
diff --git a/fs/namespace.c b/fs/namespace.c
index 2f3c6a0350a8..39569c215bab 100644
--- a/fs/namespace.c
+++ b/fs/namespace.c
@@ -3019,6 +3019,7 @@ int ksys_mount(char __user *dev_name, char __user *dir_name, char __user *type,
        char *kernel_type;
        char *kernel_dev;
        void *options;
+        char  *k_dir_name = strndup_user(dir_name, PATH_MAX);
 
        kernel_type = copy_mount_string(type);
        ret = PTR_ERR(kernel_type);
@@ -3035,7 +3036,9 @@ int ksys_mount(char __user *dev_name, char __user *dir_name, char __user *type,
        if (IS_ERR(options))
                goto out_data;
 
+        printk("lsken00 --- do_mount kernel_dev = %s; k_dir_name = %s\n", kernel_dev, k_dir_name);
        ret = do_mount(kernel_dev, dir_name, kernel_type, flags, options);
+        printk("lsken00 --- do_mount end \n");
 
        kfree(options);
```

#### 4.19

- spi start :        1.898291
- rootfs mount end:   5.305296
- iot_usb_dock end:   6.056671
- nandread test:    12.488889

```sh
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
real    0m 5.08s
user    0m 0.02s
sys     0m 2.06s
```

#### 5.15 默认

- spi start :         2.511331
- rootfs mount end:   6.075754
- iot_usb_dock end:   7.161908
- nandread test:      15.816891

```sh
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
real    0m 12.01s
user    0m 0.03s
sys     0m 2.59s
```

#### 5.15 修改

- spi start :         2.346131
- rootfs mount end:   6.015829
- iot_usb_dock end:   7.145709
- nandread test:      14.219185

```sh
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
real    0m 1.90s
user    0m 0.03s
sys     0m 1.48s
```

### 总结

- 调整 ko 加载顺序

见附件：early_load_ko_5.15.rc-jiucheng

- 修改 init.rc.base

```sh
--- a/korlan/init.rc.base
+++ b/korlan/init.rc.base
@@ -366,7 +366,9 @@ on boot
     start servicemanager
 
     # Note: this daemon is expected to call `setprop chrome.usb.init init-me`
+    write /dev/kmsg "TEST: iot_usb_dock start  lsken00"
     start iot_usb_dock
+    write /dev/kmsg "TEST: iot_usb_dock end  lsken00"
 
     # depends on device certificate in /factory_setting and kernal flags
     # network_service.sh starts bluetooth and wifi services if necessary.
@@ -436,6 +438,10 @@ on boot
     # set uac and tdm affinities to CPU-1
     exec /bin/sh /sbin/pcie_affinity.sh
 
+    #exec /system/bin/sleep 5
+    write /dev/kmsg "TEST : nandread  lsken00"
+    exec /sbin/busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
+
 ## Daemon processes to be run by init.
```

- 测试

```sh
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
```

#### 总结回复 google

- 4.19

```
spi_probe:                   1.489926
rootfs mount end:            3.625621
iot_usb_dock                 4.267736
time test_cast_auth test :   9.923957
```

- 5.15 默认

```
spi_probe:                   2.538475
rootfs mount end:            6.178444
iot_usb_dock                 7.295909
time test_cast_auth test :   14.650420
```

- 5.15 change

```
spi_probe:                   2.364961
rootfs mount end:            6.096657
iot_usb_dock                 7.135366
time test_cast_auth test :   14.226662
```

Hi Yi,

I am working on Optimize kernel config. It is interesting to find that when adding these patches and cropping some config, the problem of comment #4 does not appear again.

Here is cl about kernel tailoring.

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/268826
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/268825
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/270868
```



## kernel 裁剪

https://partnerissuetracker.corp.google.com/issues/235426120

> 裁剪 1m


### kernel 裁剪优化记录

查看大小

```
 ./arch/arm64/boot/kernel.korlan.gz-dtb.korlan-b1
```

- 打上这两个 patch 前的大小

```sh
-rw-r--r--  1 shengken.lin szsoftware  6247908 Nov 25 23:59 kernel.korlan.gz-dtb.korlan-p2
```

- 优化后

```sh
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/268825

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/268826

-rw-r--r--  1 shengken.lin szsoftware  5241185 Dec  6 10:28 kernel.korlan.gz-dtb.korlan-p2


# Device Drivers  ---> SCSI device support  ---> SCSI device support
-rw-r--r--  1 shengken.lin szsoftware  5143260 Dec  8 10:18 kernel.korlan.gz-dtb.korlan-p2


#  < > VFAT (Windows-95) fs support    关掉这个
-rw-r--r--  1 shengken.lin szsoftware  5137860 Dec  8 10:39 kernel.korlan.gz-dtb.korlan-p2



# Device Drivers  ---> --- Network device support  <*>   USB Network Adapters  --->  ？？？
# ASIX AX88xxx Based USB 2.0 Ethernet Adapters  使用 AX88772B 模块进行扩展百兆网口
# <*>     ASIX AX88179/178A USB 3.0/2.0 to Gigabit Ethernet
# 但是如果需要支持 host 模糊下的 usb disk, 需要开启 （再选择 USB support，按回车进入USB support 菜单,找到并选中“ USB Mass Storage support”）
# 参考 https://blog.csdn.net/weixin_42280315/article/details/116606455

# 直接全部关闭 USB Network Adapters     --   Multi-purpose USB Networking Framework
-rw-r--r--  1 shengken.lin szsoftware  5096888 Dec  8 16:37 kernel.korlan.gz-dtb.korlan-p2

```

commit id : 2ec287b739a6406664d6a6777109f6464976603e



Hi Yi,

Based on comment#43, I made more cropping, please review this cl.

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/270868
```

eureka-v2 commit Id: 62d8fe0cb22be5de4ce0e00a532cbda8e1edca12


## Korlan 开机声卡顿问题

https://partnerissuetracker.corp.google.com/issues/262155155  comment#23

```sh
cat /sys/module/u_audio/parameters/free_run 
```

- 在 PC 端播放 音频，
- 然后 echo 0 > /sys/module/u_audio/parameters/free_run
  - 这时会没有声音
- aplay -Dhw:0,0 /data/the-stars-48k-60s.wav
- echo 1 > /sys/module/u_audio/parameters/free_run   
  - 这时 PC 的音乐开始
- 这时候 crtl+C 掉 aplay
- 发现 PC 的音乐也停止了


free_run 标志的位置： korlan-sdk/kernel/drivers/usb/gadget/function/u_audio.c

tdm 开始和关闭：korlan-sdk/kernel/sound/soc/amlogic/auge/tdm.c

在 PC 继续播放时，手动修改

这时 free_run 为 1

```
echo 0 > /sys/module/u_audio/parameters/free_run   
echo 1 > /sys/module/u_audio/parameters/free_run   
```

就可以正常运行

Thanks for Mingyu update, please let us if it still our assistance.

----


## tdm_bridge 优化

> https://partnerissuetracker.corp.google.com/issues/262352934  


- 增加一个状态值

-----

Hi Mingyu,

Here is fix comment #1 cl

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/275167
```

In addition, I tested the following cases, 

- case 1:  aplay *.wav ,and connect uac, wait aplay finish, uac work normal.
- case 2:  aplay *.wav ,and connect uac, manunal stop aplay, uac work normal.
- case 3:  aplay *.wav , and connect uac, uac stop,  aplay work normal.
- case 4:  uac working, and aplay *.wav ( tdm is busy), uac stop, then aplay *.wav again, the sound of the aplay disappears after a period of time.
  -  `amixer cset numid=3 on;`  aplay  work fine.

---

## 开启并制作 erofs 文件系统


参考：

- https://blog.csdn.net/ZR_Lang/article/details/88859477

- https://tjtech.me/how-to-build-mkfs-erofs-for-arm64.html

- https://blog.csdn.net/u014001096/article/details/124831748

- 源码 readme https://android.googlesource.com/platform/external/erofs-utils/+/refs/heads/master/README

### 下载和编译 erofs-utils

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



### 压缩到 image

先创建一个文件夹并拷贝一些文件进去

```sh
srcd/
├── ChangeLog
├── COPYING
├── Makefile
└── README
```

打包制作 img

```sh
./mkfs.erofs  erofs.img srcd/
adb push erofs.img /data/

chmod 777 ./erofs.img 
mkdir /data/aaa/
# 挂载
mount -t erofs /data/erofs.img /data/aaa/ -o loop

/data/aaa # ls -l /data/aaa/
-rw-r--r-- 9515     8000          585 2023-01-05 00:41 COPYING
-rw-r--r-- 9515     8000         3818 2023-01-05 00:41 ChangeLog
-rw-r--r-- 9515     8000        26617 2023-01-05 00:41 Makefile
-rw-r--r-- 9515     8000         9867 2023-01-05 00:41 README
```


### 学习给korlan增加一个分区



- google_source/eureka/korlan-sdk/u-boot/board/amlogic/a1_korlan_p2/a1_korlan_p2.c

- kernel-5.15/common_drivers/arch/arm64/boot/dts/amlogic/korlan-common.dtsi

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

- 板子上查看 

```sh
# 板子上查看 分区
cat /proc/mtd

# 增加一个 block dev
ls /dev/block/mtdblock8 

# 注意 cache 默认是 mtd7
# 可以在 init.rc 中查看
# exec /bin/sh /sbin/check_and_mount_ubifs.sh 7 cache /cache 20 
```

-----

### 读取分区表

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

# 对比 system_1.bin 和 erofs.img
第一种方法： 将后缀改成一样然后用 compare 工具比较
第二种方法：
hexdump -C system_1.bin > system_1.bin.txt 
hexdump -C erofs.img > erofs.img.txt 
vim -d erofs.img.txt  system_1.bin.txt 


# 挂载
mount -t erofs /dev/block/mtdblock8  /data/aaa/
```


### 将自己制作的文件系统挂载起来

#### 解决分区不足和不支持 lz4 压缩问题

erofs 默认支持 lz4 压缩算法，所以需要安装相应的库，不然 .configure 时会关闭 lz4

所以需要去 ubuntu 中编译支持 liblz4-dev 的  mkfs.erofs

```sh
git clone git://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git

# 需要下载一下插件
sudo apt-get install autotools-dev 
sudo apt-get install automake

sudo apt-get install uuid-dev
sudo apt-get install liblz4-dev
apt-cache search liblz4-dev  # 服务器上没有

cd erofs-utils
./autogen.sh
./configure
make -j4

cp mkfs.erofs /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/host/linux-x86/bin/ -rf
```

- 修改 ota_from_target_files 支持 erofs

```sh
vim chrome/vendor/amlogic/build/tools/releasetools/ota_from_target_files +1059
cp mkfs.erofs /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/out/host/linux-x86/bin/ -rf
```

- python 打印行号

```py
print('Print Message: lsken00 ========>  ' + ' ,File: "'+__file__+'", Line '+str(sys._getframe().f_lineno)+' , in '+sys._getframe().f_code.co_name)
```

- 制作文件系统命令

```sh
# mksquashfs rootfs ./rootfs.squashfs.img -b 64K –comp xz
./mkfs.erofs -zlz4 -C65536 ./erofs.img.3 ./srcd/ -E context_file_path  # (linux的参数)

./mkfs.erofs  -C65536 ./erofs.img.2 ./srcd/

sudo apt-get install liblz4-dev
 ```

 測試不用 device mapper 是否能 mount

 exec /sbin/busybox mount -t erofs /dev/block/mtdblock6 /system.ro

 ### 解决 Permission denied 问题

https://blog.51cto.com/u_15076212/4373946


打开 kernel log

vim vendor/amlogic/korlan/BoardConfigCommon.mk  +81

init log

write /dev/kmsg "TEST : =============222  lsken00"

----


- 提交 

- common_drivers

```
[Don't merge][korlan] Add system partition compatible with erofs.

Bug: None
Test: build ok & adb work fine
```

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276586

- kernel-5.15

```
[Don't merge][korlan] Enable erofs.

Bug: None
Test: build ok & adb work fine
```

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/276587

- u-boot

```
[Don't merge][korlan] Add system partition compatible with erofs.

Bug: None
Test: build ok & adb work fine
```

https://eureka-partner-review.googlesource.com/c/amlogic/u-boot/+/276588

- vendor/amlogic

git add korlan/init.rc.base
git add build/tools/releasetools/ota_from_target_files

```
[Don't merge][korlan] Add erofs support and mount erofs.

Bug: None
Test:
/ # mount | grep erofs
/dev/mapper/system /system.ro erofs ro,nodev,noatime,user_xattr,acl,cache_strategy=readaround 0 0
```

git push eureka HEAD:refs/for/master

commit id: b3a57d7b691db111e027f19e8e58eb7efdc593b5
https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/276589

topic: https://eureka-partner-review.googlesource.com/q/topic:%22Enable+erofs%22



----


task1:文件性能对比测试(squashfs & erofs)：
1 IO性能。
	1) IOZONE.
	2) nandread & nandwrite.
2 记录启动时间。

task2: 对比read/write 调用栈 ， 对比两个文件系统的各自的优点缺点。
	追踪erorf 文件系统read/write，调用栈（read/write），根据调用栈，对比两个文件系统的优缺点。

task3: 研究erfos，的整个文件系统结构，输出关于erofs的 文档。


- 下載 iozone3_494.tgz

https://www.iozone.org/src/current/

或者：wget http://www.iozone.org/src/current/iozone3_487.tar

tar zxf iozone3_494.tgz 

```sh
error : /usr/bin/ld: pit_server.o: relocation R_X86_64_32 against symbol `service_name' can not be used when making a PIE object; recompile with -fPIE

chmod +w makefile 
vim makefile
CC  = cc -no-pie 

sudo  ./iozone -i 0 -i 1 -i 2 -s 64g -r 16m -f ./iozone.tmpfile -Rb ./iotest.xls
```

參考：

https://www.freesion.com/article/76691495377/


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



```sh
./iozone -a -n 4m -g 256m -i 0 -i 1 -y 4096 -q 4096 -f /system/iozone.tmpfile -Rb ./iotest.xls

busybox time nandread -d /dev/mtd/mtd6 -L 6144000 -f /cache/.data/dump-page0.hex
```

- erofs

```
/ # busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0
read 3000 pages, 0 empty
real    0m 2.93s
user    0m 0.04s
sys     0m 1.61s
/ # busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0
read 3000 pages, 0 empty
real    0m 2.66s
user    0m 0.05s
sys     0m 1.51s

/ # busybox time nandwrite /dev/mtd/mtd4 -s -0 -p /data/write_test_file 
real    0m 4.57s
user    0m 0.01s
sys     0m 1.27s

real    0m 0.67s
user    0m 0.01s
sys     0m 0.40s

/ # dmesg  | grep lsken00
[    4.109511] TEST : mount fs start  lsken00
[    4.149173] TEST : mount fs end lsken00
[    5.792701] TEST : mount other fs end lsken00


# 设置 只跟踪函数 
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo function > /sys/kernel/debug/tracing/current_tracer

echo 1 > /sys/kernel/debug/tracing/tracing_on
echo "" > /sys/kernel/debug/tracing/trace

busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0


echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace > /data/trace_01.txt
```

- squashfs

```
/ # busybox time nandread -d /dev/mtd/mtd6 -L 6144000 -f /cache/.data/dump-page
read 3000 pages, 0 empty
real    0m 2.65s
user    0m 0.02s
sys     0m 1.50s
/ # busybox time nandread -d /dev/mtd/mtd6 -L 6144000 -f /cache/.data/dump-page
read 3000 pages, 0 empty
real    0m 1.76s
user    0m 0.04s
sys     0m 1.38s

/ # busybox time nandwrite /dev/mtd/mtd4 -s -0 -p /data/write_test_file 
real    0m 4.10s
user    0m 0.01s
sys     0m 1.28s

/ # dmesg | grep lsken00
[    4.090602] TEST : mount fs start  lsken00
[    4.374924] TEST : mount fs end lsken00
[    5.910525] TEST : mount other fs end lsken00
```

## kernel 4.19 功能迁移到 kernel 5.4

使用 A5 的板子验证

target: google audio brige -> kernel5.4
-> usb & uac & tdmoutb & HIFI


1 Repo sync a5 buildroot code (kernel5.4)
2 buildroot & run  & usb(adbd) & uac
3 google kernel4.9 --> kernel kernel5.4  
   usb controller.


### 修改 功放板 patch

Change power amplifier driver board from D622 to D613

d6e9202cf8d66f4ef616eee66a7d4c3363653a74

https://scgit.amlogic.com/#/c/292999/

### 打开 UAC

参考 korlan 打开 A4 的 https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/248628


- 打开 kernel uac

首先找到 kernel 的 defconfig 文件

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

保存到  ./output/a5_av400_spk_a6432_release/build/linux-amlogic-5.4-dev/defconfig


----







