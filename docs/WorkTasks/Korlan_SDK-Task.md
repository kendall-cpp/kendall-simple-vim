- [TASK：测试 i2s clock](#task测试-i2s-clock)
  - [在 Ubuntu 下测试](#在-ubuntu-下测试)
  - [最终提交1](#最终提交1)
  - [最终提交2](#最终提交2)
  - [复现 dock-test-tool 测试问题](#复现-dock-test-tool-测试问题)
- [添加 dhcp fct-korlan](#添加-dhcp-fct-korlan)
  - [kernel 打开个 CONFIG\_USB\_RTL8152](#kernel-打开个-config_usb_rtl8152)
  - [fctory 设置 IP](#fctory-设置-ip)
  - [设置开机自动获取 ip](#设置开机自动获取-ip)
  - [adb调试ipv6](#adb调试ipv6)
  - [开启 ipv6和RTL8152](#开启-ipv6和rtl8152)
  - [重新编译成 ko 文件，并加载到init.rc](#重新编译成-ko-文件并加载到initrc)
    - [提交](#提交)
- [熟悉和测试 korlan5.15](#熟悉和测试-korlan515)
  - [GPIO测试](#gpio测试)
    - [Set internal default pull up/down/disabled](#set-internal-default-pull-updowndisabled)
    - [GPIO event](#gpio-event)
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


## 添加 dhcp fct-korlan

> https://partnerissuetracker.corp.google.com/issues/247080714


###  kernel 打开个 CONFIG_USB_RTL8152

arch/arm64/configs/korlan-p2_defconfig

CONFIG_USB_RTL8152=y


### fctory 设置 IP
  
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

- connect rejected

```c
system/core/adb/transport_local.c::server_socket_thread():server: cannot bind socket yet
```


```c
  352 //#  define ADB_TRACING  ((adb_trace_mask & (1 << TRACE_TAG)) != 0)
  353 #  define ADB_TRACING  1
  354                                                                                                                                                                                                                        
  355   /* you must define TRACE_TAG before using this macro */
  356 #  define  D(...)                                      \
  357         do {                                           \
  358             if (ADB_TRACING) {                         \
  359                 int save_errno = errno;                \
  360                 adb_mutex_lock(&D_lock);               \
  361                 fprintf(stdout, "%s::%s():",           \
  362                         __FILE__, __FUNCTION__);       \
  363                 errno = save_errno;                    \
  364                 fprintf(stdout, __VA_ARGS__ );         \
  365                 fflush(stdout);                        \
  366                 adb_mutex_unlock(&D_lock);             \
  367                 errno = save_errno;                    \
  368            }                                           \
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

### 开启 ipv6和RTL8152


### 重新编译成 ko 文件，并加载到init.rc

拷贝到 ramdisk sbin 目录下

```
cp kernel/net/ipv6/ipv6.ko  /mnt/fileroot/shengken.lin/workspace/google_source/eureka/amlogic_sdk/build-sign-pdk/korlan/fct_ramdisk/sbin

- 顺序，只需要

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

### GPIO测试

和 4.19 进行对比

```sh
# step1 check pin mux function,
cat /sys/kernel/debug/pinctrl/fe000000.bus:pinctrl@0400-pinctrl-meson/pinmux-pins


# step2:
cat /sys/kernel/debug/pinctrl/fe000000.bus:pinctrl@0400-pinctrl-meson/pinconf-pins

# kernel-5.15/common_drivers/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
检查kernel的： drive-strength-microamp   ===》 step2 log 中的 drive strength (3 mA)
和 kernel/arch/arm64/boot/dts/amlogic/meson-a1.dtsi 对比
```

#### Set internal default pull up/down/disabled


#### GPIO event

参考测试cl: https://partnerissuetracker.corp.google.com/issues/195367613


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

## nandread去读卡

> https://jira.amlogic.com/browse/GH-3176

###  yuegui 飞书记录

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

echo 1 > /sys/kernel/debug/tracing/tracing_on
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex
echo 0 > /sys/kernel/debug/tracing/tracing_on
dd if=/sys/kernel/debug/tracing/trace of=/tmp/trace.bringup.bin bs=1M
```

```
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo 0 > /sys/kernel/debug/tracing/events/enable
echo ""  > /sys/kernel/debug/tracing/trace
echo 40960 > /sys/kernel/debug/tracing/buffer_size_kb

echo 1 > /sys/kernel/debug/tracing/options/record-tgid
echo 1 > /sys/kernel/debug/tracing/events/ipi/enable
echo 1 > /sys/kernel/debug/tracing/events/irq/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/enable
echo 1 > /sys/kernel/debug/tracing/events/timer/enable
echo 1 > /sys/kernel/debug/tracing/events/power/cpu_idle/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable
echo 1 > /sys/kernel/debug/tracing/tracing_on
busybox time nandread -d /dev/mtd/mtd4 -L 6144000 -f /cache/.data/dump-page0.hex &
sleep 10
echo 0 > /sys/kernel/debug/tracing/tracing_on
dd if=/sys/kernel/debug/tracing/trace of=/tmp/trace bs=1M
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

# 直接全部关闭 Multi-purpose USB Networking Framework
-rw-r--r--  1 shengken.lin szsoftware  5096888 Dec  8 16:37 kernel.korlan.gz-dtb.korlan-p2

```

commit id : 2ec287b739a6406664d6a6777109f6464976603e

```sh
[Korlan] Optimize kernel config

1. Disable VFAT (Windows-95) fs
2. SCSI device
3. Multi-purpose USB Net

Bug: b/235426120
Test: build ok, tdm-bridge work fine, adb work fine.
```

Hi Yi,

Based on comment#43, I made more cropping, please review this cl.

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/270868
```

eureka-v2 commit Id: 62d8fe0cb22be5de4ce0e00a532cbda8e1edca12




