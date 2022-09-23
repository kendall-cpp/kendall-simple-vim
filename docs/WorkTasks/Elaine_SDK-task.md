
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

vim u-boot/drivers/amlogic/media/vout/lcd/lcd_vout.c 
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

