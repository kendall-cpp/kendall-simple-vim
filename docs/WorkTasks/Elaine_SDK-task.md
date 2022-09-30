
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


- 确定硬件在哪里修改了 xhci->xhc_state

- common


Hi Cody,
Our team is working hard on testing and locating the issues.

- xhci->xhc_state 分析

```c
struct usb_device *usb_alloc_dev(struct usb_device *parent,
				 struct usb_bus *bus, unsigned port1)
{
	struct usb_device *dev;
	struct usb_hcd *usb_hcd = bus_to_hcd(bus);
	unsigned root_hub = 0;
	unsigned raw_port = port1;
struct xhci_hcd *xhci = hcd_to_xhci(usb_hcd);
printk("[kendall] -- %s xhc_state=%d\n",__func__, xhci->xhc_state);
...
}
//ok
[    3.141750@1] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 2
[    3.141752@1] [kendall] -- usb_alloc_dev xhc_state=2
[    3.141808@1] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
//error
[    4.781754@2] xhci-hcd xhci-hcd.0.auto: xHCI Host Controller
[    4.787061@2] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 2
[    4.790034@1] [GTP-INF][goodix_read_cfg_bin:440] cfg_bin_name:goodix_cfg_group_fiti9364.bin
[    4.790137@1] [GTP-INF][goodix_read_cfg_bin:450] Cfg_bin image [goodix_cfg_group_fiti9364.bin] is ready, try_times:1
[    4.790156@1] [GTP-INF][goodix_cfg_bin_proc:172] parse cfg bin SUCCESS
[    4.790159@1] [GTP-INF][goodix_get_reg_and_cfg:302] ic_type:1
[    4.802061@1] [GTP-INF][goodix_get_reg_and_cfg:316] sensor id is 0
[    4.802065@1] [GTP-ERR][goodix_get_reg_and_cfg:323] pkg:0, sensor id contrast FAILED, reg:0x4541
[    4.802069@1] [GTP-ERR][goodix_get_reg_and_cfg:326] sensor_id from i2c:0, sensor_id of cfg bin:1
[    4.802072@1] [GTP-INF][goodix_get_reg_and_cfg:302] ic_type:1
[    4.813953@1] [GTP-INF][goodix_get_reg_and_cfg:316] sensor id is 0
[    4.836171@1] [GTP-INF][goodix_get_reg_and_cfg:376] try get package info: ic type normandy_L, cfg type 1
[    4.836175@1] [GTP-INF][goodix_extract_cfg_pkg:236] get config type 1, len 651
[    4.836180@1] [GTP-INF][goodix_get_reg_and_cfg:383] success extract cfg
[    4.836182@1] [GTP-INF][goodix_get_reg_and_cfg:302] ic_type:1
[    4.848085@1] [GTP-INF][goodix_get_reg_and_cfg:316] sensor id is 0
[    4.848088@1] [GTP-ERR][goodix_get_reg_and_cfg:323] pkg:2, sensor id contrast FAILED, reg:0x4541
[    4.848091@1] [GTP-ERR][goodix_get_reg_and_cfg:326] sensor_id from i2c:0, sensor_id of cfg bin:2
[    4.848094@1] [GTP-INF][goodix_cfg_bin_proc:181] get reg and cfg from cfg_bin SUCCESS
[    4.848097@1] [GTP-INF][goodix_cfg_bin_proc:187] cfg_send_flag:0x4542
[    4.848099@1] [GTP-INF][goodix_cfg_bin_proc:188] pid:0x4535
[    4.848100@1] [GTP-INF][goodix_cfg_bin_proc:189] vid:0x453d
[    4.848102@1] [GTP-INF][goodix_cfg_bin_proc:190] sensor_id:0x4541
[    4.848104@1] [GTP-INF][goodix_cfg_bin_proc:191] fw_mask:0x0000
[    4.848105@1] [GTP-INF][goodix_cfg_bin_proc:192] fw_status:0x0000
[    4.848107@1] [GTP-INF][goodix_cfg_bin_proc:193] cfg_addr:0x60dc
[    4.848109@1] [GTP-INF][goodix_cfg_bin_proc:194] esd:0x0000
[    4.848110@1] [GTP-INF][goodix_cfg_bin_proc:195] command:0x60cc
[    4.848112@1] [GTP-INF][goodix_cfg_bin_proc:196] coor:0x4100
[    4.848113@1] [GTP-INF][goodix_cfg_bin_proc:197] gesture:0x0000
[    4.848115@1] [GTP-INF][goodix_cfg_bin_proc:198] fw_request:0x0000
[    4.848116@1] [GTP-INF][goodix_cfg_bin_proc:199] proximity:0x0000
[    4.848121@1] [GTP-INF][goodix_generic_noti_callback:1870] notify event type 0x8
[    4.848124@1] [GTP-INF][goodix_cfg_bin_proc:210] cfg bin state 2, ret 0
[    4.848127@1] [GTP-INF][goodix_later_init_thread:531] success get cfg bin
[    4.848129@1] [GTP-INF][goodix_later_init_thread:554] success parse config bin
[    4.848132@1] [GTP-INF][goodix_fw_update_thread:1045] Firmware request update starts
[    4.848136@1] [GTP-INF][goodix_request_firmware:1005] Request firmware image [goodix_firmware.bin]
[    4.848269@1] [GTP-INF][goodix_request_firmware:1010] Firmware image [goodix_firmware.bin] is ready
[    4.848272@1] [GTP-INF][goodix_register_ext_module:159] goodix_register_ext_module IN
[    4.848281@1] [GTP-INF][goodix_register_ext_module:164] goodix_register_ext_module OUT
[    4.848284@1] [GTP-INF][goodix_generic_noti_callback:1870] notify event type 0x0
[    4.848441@1] [GTP-INF][goodix_parse_firmware:249] Firmware package protocol: V2
[    4.848442@1] [GTP-INF][goodix_parse_firmware:250] Fimware PID:GT6853
[    4.848446@1] [GTP-INF][goodix_parse_firmware:252] Fimware VID:00010008
[    4.848448@1] [GTP-INF][goodix_parse_firmware:253] Firmware chip type:94
[    4.848450@1] [GTP-INF][goodix_parse_firmware:254] Firmware size:71930
[    4.848452@1] [GTP-INF][goodix_parse_firmware:255] Firmware subsystem num:11
[    4.848467@1] [GTP-INF][__do_register_ext_module:64] __do_register_ext_module IN
[    4.848470@1] [GTP-INF][__do_register_ext_module:88] start register ext_module
[    4.848475@1] [GTP-INF][__do_register_ext_module:103] Module [goodix-fwu] already exists
[    4.872688@1] [GTP-INF][goodix_read_version:760] sensor_id_mask:0x0f, sensor_id:0x00
[    4.872693@1] [GTP-INF][goodix_read_version:768] PID:6853,SensorID:0, VID:00 01 00 08 00 00 00 00
[    4.872808@1] [GTP-ERR][goodix_check_update:307] FW version is equal to the IC's
[    4.872812@1] [GTP-INF][goodix_fw_update_proc:928] fw update skiped
[    4.872814@1] [GTP-INF][goodix_fw_update_proc:984] fw update ret 0
[    4.872829@1] [GTP-INF][goodix_unregister_ext_module:220] Moudle [goodix-fwu] unregistered
[    4.872831@1] [GTP-INF][goodix_fw_update_thread:1105] fw update success
[    4.872835@1] [GTP-INF][goodix_generic_noti_callback:1870] notify event type 0x2
[    4.886764@1] [GTP-INF][goodix_read_version:760] sensor_id_mask:0x0f, sensor_id:0x00
[    4.886768@1] [GTP-INF][goodix_read_version:768] PID:6853,SensorID:0, VID:00 01 00 08 00 00 00 00
[    4.886881@1] [GTP-INF][goodix_do_fw_update:1388] fw update return 0
[    4.886887@1] [GTP-INF][goodix_check_cfg_valid:985] cfg bag_num:39, cfg length:651
[    4.886893@1] [GTP-INF][goodix_check_cfg_valid:1021] configuration check SUCCESS
[    4.886896@1] [GTP-INF][goodix_send_config:1044] ver:2dh,size:651
[    4.998547@2] [kendall] -- usb_alloc_dev xhc_state=2
[    4.998556@2] usb usb1-port2: couldn't allocate usb_device
[    5.003003@0] [GTP-INF][goodix_send_large_config:931] Send large cfg SUCCESS
[    5.017142@0] [GTP-INF][goodix_read_version:760] sensor_id_mask:0x0f, sensor_id:0x00
[    5.017146@0] [GTP-INF][goodix_read_version:768] PID:6853,SensorID:0, VID:00 01 00 08 00 00 00 00
[    5.017439@0] input: goodix_ts as /devices/virtual/input/input3
[    5.017694@0] [GTP-INF][goodix_ts_irq_setup:1092] IRQ:61,flags:2
[    5.017847@0] [GTP-INF][goodix_ts_stage2_init:1924] success register irq
[    5.017883@0] [GTP-INF][goodix_ts_esd_init:1590] key parameters unset for esd check
[    5.017885@0] [GTP-INF][goodix_later_init_thread:565] stage2 init success
[    5.307593@2] [kendall] -- usb_alloc_dev xhc_state=2
[    5.312573@2] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
```

多执行了一次 usb_alloc_dev 

create_lvs_device 不会被调用

- usb_device_supports_lpm 的调用栈

```
[    5.780472@2] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 2
[    5.788327@2] CPU: 2 PID: 1 Comm: swapper/0 Not tainted 4.9.244 #47
[    5.794496@2] Hardware name: Amlogic (DT)
[    5.798482@2] Call trace:
[    5.801087@2] [ffffff8020003700+  96][<ffffff800908b3d0>] dump_backtrace+0x0/0x278
[    5.808625@2] [ffffff8020003760+  32][<ffffff800908b3c4>] show_stack+0x20/0x2c
[    5.815819@2] [ffffff8020003780+  48][<ffffff80093dca80>] dump_stack+0xd4/0x110
[    5.823099@2] [ffffff80200037b0+  32][<ffffff8009543854>] usb_device_supports_lpm+0xb4/0xc4
[    5.831418@2] [ffffff80200037d0+  80][<ffffff800954df48>] usb_add_hcd+0x4bc/0x72c
[    5.838872@2] [ffffff8020003820+  80][<ffffff800958ab3c>] xhci_plat_probe+0x444/0x530
[    5.846673@2] [ffffff8020003870+  48][<ffffff80094c3d30>] platform_drv_probe+0x68/0xbc
[    5.854557@2] [ffffff80200038a0+  64][<ffffff80094c1574>] driver_probe_device+0x3d0/0x408
[    5.862704@2] [ffffff80200038e0+  64][<ffffff80094c1c6c>] __device_attach_driver+0xf4/0x10c
[    5.871024@2] [ffffff8020003920+  64][<ffffff80094bf4dc>] bus_for_each_drv+0x7c/0xac
[    5.878737@2] [ffffff8020003960+  48][<ffffff80094c16c8>] __device_attach+0x98/0x114
[    5.886451@2] [ffffff8020003990+  32][<ffffff80094c1764>] device_initial_probe+0x20/0x2c
[    5.894510@2] [ffffff80200039b0+  48][<ffffff80094bf6f0>] bus_probe_device+0x34/0x94
[    5.902225@2] [ffffff80200039e0+  64][<ffffff80094bc2e0>] device_add+0x330/0x4f8
[    5.909591@2] [ffffff8020003a20+ 160][<ffffff80094c38a8>] platform_device_add+0x80/0x21c
[    5.917652@2] [ffffff8020003ac0+  48][<ffffff80095660c4>] dwc3_host_init+0x214/0x2a0
[    5.925364@2] [ffffff8020003af0+  64][<ffffff8009564a00>] dwc3_core_init_mode+0x3c/0xa4
[    5.933337@2] [ffffff8020003b30+  80][<ffffff80095631f4>] dwc3_probe+0x960/0xa98
[    5.940704@2] [ffffff8020003b80+  48][<ffffff80094c3d30>] platform_drv_probe+0x68/0xbc
[    5.948591@2] [ffffff8020003bb0+  64][<ffffff80094c1574>] driver_probe_device+0x3d0/0x408
[    5.956737@2] [ffffff8020003bf0+  64][<ffffff80094c1864>] __driver_attach+0xbc/0xe8
[    5.964364@2] [ffffff8020003c30+  48][<ffffff80094bf1dc>] bus_for_each_dev+0x80/0xb0
[    5.972077@2] [ffffff8020003c60+  32][<ffffff80094c179c>] driver_attach+0x2c/0x38
[    5.979530@2] [ffffff8020003c80+  48][<ffffff80094bf9a0>] bus_add_driver+0x120/0x1e8
[    5.987244@2] [ffffff8020003cb0+  32][<ffffff80094c25d8>] driver_register+0xa8/0xf4
[    5.994871@2] [ffffff8020003cd0+  48][<ffffff80094c3ecc>] __platform_driver_probe+0x9c/0x104
[    6.003279@2] [ffffff8020003d00+ 256][<ffffff8009ebcd0c>] amlogic_dwc3_init+0x20/0x28
[    6.011079@2] [ffffff8020003e00+  64][<ffffff8009083d10>] do_one_initcall+0xd8/0x194
[    6.018792@2] [ffffff8020003e40+  96][<ffffff8009e80ef4>] kernel_init_freeable+0x1b0/0x240
[    6.027025@2] [ffffff8020003ea0+   0][<ffffff8009b4f4c8>] kernel_init+0x14/0x1f8
[    6.034390@2] [0000000000000000+   0][<ffffff8009083b40>] ret_from_fork+0x10/0x50
[    6.041912@2] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
```

- usb_add_hcd 的调用栈

```
[    5.533216@2] CPU: 2 PID: 1 Comm: swapper/0 Not tainted 4.9.244 #47
[    5.539437@2] Hardware name: Amlogic (DT)
[    5.543424@2] Call trace:
[    5.546032@2] [ffffff8020003720+  96][<ffffff800908b3d0>] dump_backtrace+0x0/0x278
[    5.553567@2] [ffffff8020003780+  32][<ffffff800908b3c4>] show_stack+0x20/0x2c
[    5.560761@2] [ffffff80200037a0+  48][<ffffff80093dca80>] dump_stack+0xd4/0x110
[    5.568040@2] [ffffff80200037d0+  80][<ffffff800954db7c>] usb_add_hcd+0xf0/0x72c
[    5.575406@2] [ffffff8020003820+  80][<ffffff800958ab3c>] xhci_plat_probe+0x444/0x530
[    5.583207@2] [ffffff8020003870+  48][<ffffff80094c3d30>] platform_drv_probe+0x68/0xbc
[    5.591091@2] [ffffff80200038a0+  64][<ffffff80094c1574>] driver_probe_device+0x3d0/0x408
[    5.599238@2] [ffffff80200038e0+  64][<ffffff80094c1c6c>] __device_attach_driver+0xf4/0x10c
[    5.607559@2] [ffffff8020003920+  64][<ffffff80094bf4dc>] bus_for_each_drv+0x7c/0xac
[    5.615271@2] [ffffff8020003960+  48][<ffffff80094c16c8>] __device_attach+0x98/0x114
[    5.622984@2] [ffffff8020003990+  32][<ffffff80094c1764>] device_initial_probe+0x20/0x2c
[    5.631044@2] [ffffff80200039b0+  48][<ffffff80094bf6f0>] bus_probe_device+0x34/0x94
[    5.638761@2] [ffffff80200039e0+  64][<ffffff80094bc2e0>] device_add+0x330/0x4f8
[    5.646125@2] [ffffff8020003a20+ 160][<ffffff80094c38a8>] platform_device_add+0x80/0x21c
[    5.654186@2] [ffffff8020003ac0+  48][<ffffff80095660c4>] dwc3_host_init+0x214/0x2a0
[    5.661899@2] [ffffff8020003af0+  64][<ffffff8009564a00>] dwc3_core_init_mode+0x3c/0xa4
[    5.669871@2] [ffffff8020003b30+  80][<ffffff80095631f4>] dwc3_probe+0x960/0xa98
[    5.677238@2] [ffffff8020003b80+  48][<ffffff80094c3d30>] platform_drv_probe+0x68/0xbc
[    5.685124@2] [ffffff8020003bb0+  64][<ffffff80094c1574>] driver_probe_device+0x3d0/0x408
[    5.693270@2] [ffffff8020003bf0+  64][<ffffff80094c1864>] __driver_attach+0xbc/0xe8
[    5.700897@2] [ffffff8020003c30+  48][<ffffff80094bf1dc>] bus_for_each_dev+0x80/0xb0
[    5.708610@2] [ffffff8020003c60+  32][<ffffff80094c179c>] driver_attach+0x2c/0x38
[    5.716064@2] [ffffff8020003c80+  48][<ffffff80094bf9a0>] bus_add_driver+0x120/0x1e8
[    5.723777@2] [ffffff8020003cb0+  32][<ffffff80094c25d8>] driver_register+0xa8/0xf4
[    5.731404@2] [ffffff8020003cd0+  48][<ffffff80094c3ecc>] __platform_driver_probe+0x9c/0x104
[    5.739813@2] [ffffff8020003d00+ 256][<ffffff8009ebcd0c>] amlogic_dwc3_init+0x20/0x28
[    5.747611@2] [ffffff8020003e00+  64][<ffffff8009083d10>] do_one_initcall+0xd8/0x194
[    5.755327@2] [ffffff8020003e40+  96][<ffffff8009e80ef4>] kernel_init_freeable+0x1b0/0x240
[    5.763560@2] [ffffff8020003ea0+   0][<ffffff8009b4f4c8>] kernel_init+0x14/0x1f8
[    5.770924@2] [0000000000000000+   0][<ffffff8009083b40>] ret_from_fork+0x10/0x50
[    5.778480@2] -----
[    5.780472@2] xhci-hcd xhci-hcd.0.auto: new USB bus registered, assigned bus number 2
```

---

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