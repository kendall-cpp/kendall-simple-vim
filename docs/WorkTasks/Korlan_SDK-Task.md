- [TASK：测试 i2s clock](#task测试-i2s-clock)
  - [在 Ubuntu 下测试](#在-ubuntu-下测试)
  - [最终提交1](#最终提交1)
  - [最终提交2](#最终提交2)
  - [复现 dock-test-tool 测试问题](#复现-dock-test-tool-测试问题)
- [添加 dhcp fct-korlan](#添加-dhcp-fct-korlan)
  - [kernel 打开个 CONFIG_USB_RTL8152](#kernel-打开个-config_usb_rtl8152)
  - [fctory 设置 IP](#fctory-设置-ip)
  - [设置开机自动获取 ip](#设置开机自动获取-ip)
  - [adb调试ipv6](#adb调试ipv6)
  - [开启 ipv6和RTL8152](#开启-ipv6和rtl8152)
  - [重新编译成 ko 文件，并加载到init.rc](#重新编译成-ko-文件并加载到initrc)
    - [提交](#提交)


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

