
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

- 分析代码

```
of_property_read_string_index
|
|---of_property_read_string_helper
    |
    |---of_find_property
        |
        |---of_find_property
            |
            |---__of_find_property
                |
                |---of_prop_cmp
```

- of_property_read_string_index

参数 np 指向设备节点；propname 指向属性名字；output 参数用于存储指定的字符串；index 用于指定字符串在 string-list 中的索引。
函数直接调用 of_property_read_string_helper() 函数获得多个字符串。

- of_property_read_string_helper

参数 np 指向设备节点；propname 指向属性名字；out_strs 参数用于存储指定的字符 串；sz 参数指定了读取字符串的数量；skip 参数指定了从第几个字符串开始读取。

函数首先调用 of_find_property() 函数获得 propname 对应的属性，然后对获得的属性 和属性值进行有效性检查，检查不过直接返回错误；如果检查通过，接着计算属性的结束 地址后，使用 for 循环遍历属性的值，并且跳过 skip 对应的地址，然后将字符串都存 储在 out_strs 参数里。


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


- 通过 ssh 发送命令

ssh nick@xxx.xxx.xxx.xxx "df -h"

- 分析代码


- 分析

```
couldn't allocate usb_device
--> 出现在 drivers/usb/core/hub.c
是因为 udev = usb_alloc_dev(hdev, hdev->bus, port1); 返回null
        --> drivers/usb/core/usb.c  ---- 
        if (usb_hcd->driver->alloc_dev && parent && !usb_hcd->driver->alloc_dev(usb_hcd, dev))  的 alloc_dev 返回 0
        alloc_dev 是指针函数 --- xhci_alloc_dev
                --> drivers/usb/host/xhci.c
                ret = xhci_queue_slot_control(xhci, command, TRB_ENABLE_SLOT, 0);   
                        --> queue_command --> if ((xhci->xhc_state & XHCI_STATE_DYING) || (xhci->xhc_state & HCI_STATE_HALTED))   //drivers/usb/host/xhci-ring.c 
                        所以问题是 xhci
/*
xhci 是从 drivers/usb/host/xhci.c 传进来， 由  hcd_to_xhci(hcd) 返回
        hcd 就是 xhci_alloc_dev(alloc_dev 函数指针传进来的)
        在 drivers/usb/core/usb.c 中的 struct usb_hcd *usb_hcd = bus_to_hcd(bus);
        
static inline struct usb_hcd *bus_to_hcd(struct usb_bus *bus)                                        
{
    return container_of(bus, struct usb_hcd, self);
        //通过结构体内某个成员变量的地址和该变量名，以及结构体类型，找到该结构体变量的地址
        //找到bus的地址          
}
*/
```

- 问题是 xhci->xhc_state 状态出现问题



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

- 找到 hub_event

- hub的probe函数，主要是一些工作的初始化和hub的配置
- hub_configure配置hub
- hub_activate ，主要是启动 hub，我们这里传入的参数是HUB_INIT
  -  kick_hub_wq(hub); //主要是queue_work(hub_wq, &hub->events)，也就是把 hub_event 加入工作队列，开始运行

> hub_activate -- kick_hub_wq -- queue_work -- hub_event  (if (queue_work(hub_wq, &hub->events)) )

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



vim goodix_cfg_bin.c +171

        goodix_cfg_bin_proc

