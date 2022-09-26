
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

```c
drivers/usb/host/xhci-ring.c:355:                       xhci->xhc_state |= XHCI_STATE_DYING;
drivers/usb/host/xhci-ring.c:940:       xhci->xhc_state |= XHCI_STATE_DYING;
drivers/usb/host/xhci.c:115:            xhci->xhc_state |= XHCI_STATE_HALTED;
drivers/usb/host/xhci.c:691:            xhci->xhc_state |= XHCI_STATE_HALTED;
drivers/usb/host/xhci-plat.c:296:       xhci->xhc_state |= XHCI_STATE_REMOVING;
drivers/usb/host/xhci-pci.c:346:        xhci->xhc_state |= XHCI_STATE_REMOVING;
```


