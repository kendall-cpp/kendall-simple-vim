

## Failure to Configure Ethernet Interface

https://partnerissuetracker.corp.google.com/issues/246404063

### 无法进入 adb shell

```c
vim arch/arm64/boot/dts/amlogic/elaine-b3.dts 
1405     /* 1: host only, 2: device only, 3: OTG */
1406     /*controller-type = <1>;*/
1407     controller-type = <3>;   

# 进入kernel执行
#! /sbin/busybox sh
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


- 通过 ssh 发送 reboot 命令

ssh nick@xxx.xxx.xxx.xxx "df -h"


- 回复 common

Hi Cody,
1. I used an automated script to test and found that rebooting 10 to 50 times can reproduce the above problems.
2. But when I disable touchscreen drivers "goodix,gt9886", reboot test more than 180 times without reproducing the problem.

I will measure usb power with hardware colleagues, "goodix,gt9886".

And you can also test with my patch.

```c
--- a/arch/arm64/boot/dts/amlogic/elaine-b3.dts
+++ b/arch/arm64/boot/dts/amlogic/elaine-b3.dts
@@ -1021,7 +1021,7 @@
        clock-frequency = <400000>;
        gtx8@5d {
                compatible = "goodix,gt9886";
-               status = "okay";
+               status = "disable";
                reg = <0x5d>;
                goodix,irq-gpio = <&gpio GPIOZ_4 0x00>;
                goodix,reset-gpio = <&gpio GPIOZ_9 0x00>;
```


---

### delay load touch driver

- comment

Hi Cody,
I delay load touch driver(gt9886), usb ethernet work fine.

Here is cl 
```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/255070
```

During Chinese National Day， I will stress test this cl.


- push

git add drivers/input/touchscreen/goodix_touch_gtx8/goodix_ts_i2c.c

git commit -s

git push eureka-partner HEAD:refs/for/elaine

```

[Elaine] Delay Load Touch Driver (GT9886) to make Ethernet work properly	

Bug: b/246404063
Test:
    Repeatedly rebooting the devices by sending the reboot command over SSH.

```

This is a potential workaround, I will keep digging into the root cause, but since the reproducing rate is petty low, it seems related to hardware, but not an SW logic issue, it is not easy to find the root cause, will take a longer time debugging.

Hope the workaround can unblock your release.

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/255070

---

### 分析 hub_event

- hub的probe函数，主要是一些工作的初始化和hub的配置
- hub_configure配置hub
- hub_activate ，主要是启动 hub，我们这里传入的参数是HUB_INIT
  -  kick_hub_wq(hub); //主要是queue_work(hub_wq, &hub->events)，也就是把 hub_event 加入工作队列，开始运行

> hub_activate（init 3) -- kick_hub_wq -- queue_work -- hub_event  (if (queue_work(hub_wq, &hub->events)) )

- hub_event，前面int2的时候有设置 hub->test_bits，这里会进行处理
- port_event 做了什么
- hub_port_connect_change： 处理端口改变的情况
  - 什么情况下, hub_port_connect_change 才会被设为1.
        - 1:端口在 hub->test_bits 中被置位.搜索整个代码,在设置 hub->test_bits 的地方,只有在hub_port_logical_disconnect()中手动将端口禁用,会将对应位置1.
        - 2:hub上设备树上没有这个端口上的设备.但显示端口已经连上了设备
        - 3:hub这个端口上的连接发生了改变,从端口有设备连接变为无设备连接,或者从无设备连接变为有设备连接.
        - 4:hub的端口变为了disable,此时这个端口上连接了设备,但被显示该端口已经变禁用,需要将connect_change设为1.
        - 5:端口状态从SUSPEND变成了RESUME,远程唤醒端口上的设备失败,就需要将connect_change设为1.
- usb_port_connect_change 再调用 hub_port_connect 报错
- usb_alloc_dev 报错

当usb设备插入usb接口后，hub_irq执行，启动工作队列执行hub_event工作，它检测到port状态的变化,调用hub_port_connect_change(),如果是新设备那么usb_allco_dev，然后调用usb_new_device来进行配置使usb设备可以正常工作。




HI Chris,

I've detected that the problem might be in the goodix_get_reg_and_cfg function, However, through testing, it should not be a logical problem. It may take some additional experiments to locate the root cause.



----

### 检查 func2 和 func3

The superspeed hub except for root hub has to use Hub Depth value as an offset into the route string to locate the bits it uses to determine the downstream port number. So hub driver should send a set hub depth request to superspeed hub after the superspeed hub is set configuration in initialization or reset procedure.    

After a resume, port power should still be on. For any other type of activation, turn it on. 

- comment

commit

```

    [Elaine] Fixed probabilistic fail of usb Ethernet in rebooting
    
    Adding flag ensures that hub_init_func3 is executed after hub_init_func2 has finished.
    
    Bug: b/246404063
    Test: None
    
    Signed-off-by: shengken lin <shengken.lin@amlogic.corp-partner.google.com>
    Change-Id: I57f24ce1517d4581a7e404cffc3e6e4c62f4e841
```

Hi Chris,

I did some experimental verification and found that the work queue of hub_init_func3 is ahead of schedule, which can be solved by the following cl, and you can also test it through the following cl.

But this is still not the root cause, I will continue to work hard to study this issue, or you have better methods can also be provided to me.

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/259656
commitId: 6b7f44b5eed0a00ef73bb94dbf5c64551fdb40a9
```


### kernel-patch 参考


Fix the issue by refer to the kernel patch: https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/usb.git/commit/?h=usb-testing&id=a44623d9279086c89f631201d993aa332f7c9e66


- 参考连接
        - https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1968210    
        - https://bugzilla.kernel.org/show_bug.cgi?id=214021      
        - https://www.spinics.net/lists/linux-usb/msg226204.html  
        - https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/usb.git/commit/?h=usb-testing&id=a44623d9279086c89f631201d993aa332f7c9e66


我的测试提交： 25df54c14276675ec7d2368c91bacae053ecbb25

---- 

Hi Cody,

After a few days of hard research, I just found the root cause and solved it today.

This is a common problem because the kernel needs to register two hcds (primary_hcd and shared_hcd) for usb2 and usb3 compatibility, but once the primary roothub is registered, port state changes are handled even before xHCi is running, resulting in a USB device not detected.

At present, I have found the corresponding patch from the upstream to fix the problem. However, the 8th bit used in this patch is occupied by `HCD_FLAG_DEV_AUTHORIZED` in the Elaine-Kernel version, so the 12th bit is selected as "Defer roothub registration", After my repeated testing and verification, the patch can fix the bug of USB Ethernet failure at booting.


- Here is the patch link

```
https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/usb.git/commit/?h=usb-testing&id=a44623d9279086c89f631201d993aa332f7c9e66

https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/usb.git/commit/?h=usb-testing&id=b7a4f9b5d0e4b6dd937678c546c0b322dd1a4054
```

- Here is cl

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/262595
```


git add drivers/usb/core/hcd.c
git add drivers/usb/host/xhci.c
git add include/linux/usb/hcd.h

git commit -s --no-verify

```sh
[Elaine] Fixed probabilistic fail of USB Ethernet at rebooting

Set "HCD_FLAG_DEFER_RH_REGISTER" to hcd->flags in xhci_run() to defer registering primary roothub in usb_add_hcd() if xhci has two roothubs.

Upstream origin patch:
<1>patch1: https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/usb.git/commit/?h=usb-testing&id=a44623d9279086c89f631201d993aa332f7c9e66
<2>patch2: https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/usb.git/commit/?h=usb-testing&id=b7a4f9b5d0e4b6dd937678c546c0b322dd1a4054


Bug: b/246404063
Test: 
Repeatedly rebooting Elaine by sending the reboot command over SSH.
```

git push eureka-partner HEAD:refs/for/elaine

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/262595
commit id : 934882f98b37c0485de4850f7f1f7001d6c3c269
issue: https://partnerissuetracker.corp.google.com/issues/246404063#comment2
```


----

## GPIO bug

https://jira.amlogic.com/browse/GH-3038

- sync elaine

```sh
mkdir elaine-sdk
repo init -u https://eureka-partner.googlesource.com/amlogic/manifest -b elaine -m combined_sdk.xml
repo sync
```

- 编译

```sh
# ./sdk/build_scripts/build_all.sh ../chrome elaine-b4

./build_uboot.sh elaine-b3 ./../../chrome release
```

- 编译找到 error log

```sh
vim arch/arm64/boot/dts/amlogic/elaine-sm1-panel.dtsi 

vim u-boot/drivers/amlogic/media/vout/lcd/lcd_common.c
```

-----

## 测试 mali-driver

checkout https://eureka-partner-review.googlesource.com/c/amlogic/mali-driver/+/270825

编译命令

```sh
 ./build_mali.sh elaine-b1
```