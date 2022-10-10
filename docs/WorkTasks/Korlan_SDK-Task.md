- [TASK：测试 i2s clock](#task测试-i2s-clock)
  - [在 Ubuntu 下测试](#在-ubuntu-下测试)
- [提交](#提交)
  - [最终提交1](#最终提交1)
  - [最终提交2](#最终提交2)
- [Task: AC status `connected_status` not truly reflect the state when T6 docked](#task-ac-status-connected_status-not-truly-reflect-the-state-when-t6-docked)
- [复现 dock-test-tool 测试问题](#复现-dock-test-tool-测试问题)
- [添加 dhcp](#添加-dhcp)


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

## 提交


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

## Task: AC status `connected_status` not truly reflect the state when T6 docked 

> https://partnerissuetracker.corp.google.com/issues/244842099

## 复现 dock-test-tool 测试问题

https://partnerissuetracker.corp.google.com/issues/245839768


- 下载最新 alaine-ota 烧录


- 在 ubuntu 上进行测试

```sh
$ dd if=/dev/urandom bs=1048576 count=35 of=fake-ota.zip
$ dock-test-tool nest-ota-push --block-size=524288 ./fake-ota.zip   # 异常

$ dock-test-tool nest-ota-push  ./fake-ota.zip   # 征程
```

开始log 定位

```sh
12-31 19:00:50.365  1377  1377 I dockd   : I0101 00:00:50.362693  1377 functionfs_driver.cc:542] FUNCTIONFS_ENABLE.


# 报错点：
# 正常
12-31 19:00:39.095  1377  1377 I dockd   : I0101 00:00:39.094580  1377 functionfs_driver.cc:419] Resumed IO by submitting requests.  # 异常没有

2-31 19:00:39.103  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:usb_connection_monitor.cc(140)] State chord is INVALID. AudioState:2 DockingState:0 ProtocolState:1
12-31 19:00:39.104  1464  1464 I iot_usb_dock.sh: [1464:1682:INFO:dock_storage_manager.cc(175)] Stop metrics uploading.
12-31 19:00:39.272  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:usb_dock_ota.cc(314)] Downloaded ota chunk. size=65536

# 异常
12-31 19:00:50.372  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:usb_connection_monitor.cc(140)] State chord is INVALID. AudioState:2 DockingState:0 ProtocolState:1
12-31 19:00:50.374  1464  1464 I iot_usb_dock.sh: [1464:1671:INFO:dock_storage_manager.cc(175)] Stop metrics uploading.
12-31 19:00:52.368  1464  1464 I iot_usb_dock.sh: [1464:1464:ERROR:usb_connection_monitor.cc(151)] USB connection state NOT agreed. AudioState:2 DockingState:0 ProtocolState:1
12-31 19:00:52.997  1464  1464 I iot_usb_dock.sh: [1464:1464:INFO:message_router.cc(433)] Set stream to halt. buffered=294784, min_size=524481
```



```sh
vim ./cast/internal/iot_services/usb_dock/usb_connection_monitor.cc +140
vim ./cast/internal/iot_services/metrics/storage/dock_storage_manager.cc +175

# 分离地方
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/cast/internal/iot_services/usb_dock/usb_dock_ota.cc 
  313       if (CompareSHA1Hashes(sha1_actual, sha1_expected)) {
  314         LOG(INFO) << "OTA SHA1 hash matches. sha1=" << ToHex(sha1_actual);
  315       } else {
  316         DockResponse resp = CreateResponse(req, ResponseType::REQUEST_FAILED);                                                                                                                                         
  317         resp.set_status_message("SHA1 mismatch");
  318         return resp;
  319       }  
```

```sh
# 正常
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/cast/internal/iot_services/usb_dock/usb_dock_ota.cc --》  Downloaded ota chunk. size=65536 
HandleOtaPush -- OnNestOtaPush -- UsbDockOta::UsbDockOta (BindRepeating)（构造函数）
iot_services/usb_dock/usb_dock_ota.h --> base::WeakPtrFactory<UsbDockOta> weak_factory_{this};

# 异常
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/cast/internal/iot_services/usb_dock/usb_connection_monitor.cc  --》USB connection state NOT agreed
OnUsbConnectionDisagreeTimeout -- UsbConnectionMonitor - UsbConnectionMonitor::UsbConnectionMonitor(构造函数)
iot_services/usb_dock/usb_connection_monitor.h -> base::WeakPtrFactory<UsbConnectionMonitor> weak_factory_;


# 公共的
StopUploadingMetrics -- TEST_F （gtest）
```


- 调试和文档

https://partnerissuetracker.corp.google.com/issues/230885799

https://docs.google.com/document/d/16La7BkKlu0sbsQgruMoemk4QlBBqF8B7xHdMM74hXLk/edit?usp=sharing


## 添加 dhcp

> https://partnerissuetracker.corp.google.com/issues/247080714

```sh
service dhcpcd /bin/sh /sbin/dhcpcd_service.sh
    class service        
    user root 
```



```
[korlan] Enable dhcp


Bug: 247080714
Test:
/ # ifconfig -a
eth0      Link encap:Ethernet  HWaddr 00:e0:4c:68:02:9b
          inet addr:10.28.39.167  Bcast:10.28.39.255  Mask:255.255.255.0 
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:124 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:2 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:1000 
          RX bytes:13941 TX bytes:684 

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0 
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:1000 
          RX bytes:0 TX bytes:0
```

git push eureka HEAD:refs/for/master

https://eureka-partner-review.googlesource.com/c/vendor/amlogic/+/255325

- kernel

arch/arm64/configs/korlan-p2_defconfig

CONFIG_USB_RTL8152=y

- enable 

-rw-r--r-- 1 shengken.lin szsoftware 5935722 Sep 29 15:38 ./arch/arm64/boot/kernel.korlan.gz-dtb.korlan-b1

- disable

-rw-r--r-- 1 shengken.lin szsoftware 5899776 Sep 29 15:43 ./arch/arm64/boot/kernel.korlan.gz-dtb.korlan-b1

```
[USB] Enable RTL8152

Bug: b/247080714
Test:
/ # ifconfig -a
eth0      Link encap:Ethernet  HWaddr 00:e0:4c:68:02:9b
          inet addr:10.28.39.167  Bcast:10.28.39.255  Mask:255.255.255.0 
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:124 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:2 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:1000 
          RX bytes:13941 TX bytes:684 

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0 
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:1000 
          RX bytes:0 TX bytes:0
```

git push eureka-partner HEAD:refs/for/korlan-master

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/255326


- common

Hi Jason,

Pls use this cl,
```
https://eureka-partner-review.googlesource.com/q/topic:%22Enable+dhcp%22
```

Reply comment#6, Jason use AX88772C, this config already enable, so will not increase kernel size; And I also enable RTL8152.
- Enable RTL8152, kernel size is 5935722
- Disabled RTL8152, kernel size is 5899776

- fctory 设置 IP
  
- comment

Hi Kim,

You need to push the dhcpcd_service.sh in the attachment into the corresponding path of korlan fct (my path: /sbin/dhcpcd_service.sh),

- Modify the korlan FCT init.rc file through the following patch

```
--- a/korlan/factory/init.rc
+++ b/korlan/factory/init.rc
@@ -355,3 +355,7 @@ service logcat_kmsg_save /bin/busybox sh /bin/fct/utility/runnable_script/logcat
 service fault_logging /bin/fault_logging
     logcat
     class service
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

Hi Kim,

I used the init.rc file you provided, eth0 works fine, can you provide me with your img to reproduce your problem?

