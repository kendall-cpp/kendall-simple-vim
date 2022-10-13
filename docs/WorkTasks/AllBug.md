
## Korlan

### fct korlan 无法找到 ip

> https://partnerissuetracker.corp.google.com/issues/247080714

- 研究 dhcp 是如何启动动态 ip 和 dhcpcd 服务是什么
- 研究 CONFIG_USB_RTL8152=y 的原理

解决方法：

```sh
vim arch/arm64/configs/korlan-p2_defconfig
CONFIG_USB_RTL8152=y

# 设置 usb 为 host 模式
/ # echo 1 > /sys/kernel/debug/usb_mode/mode

# 这一步可以忽略
/ # fts -s enable_ethernet dhcp
/ # fts -g "enable_ethernet"
dhcp

# 启动 dhcpcd
start dhcpcd

# 查看 ip
ifconfig -a
```

- 解决 adb connect 被解决问题

        - 需要研究 abd
        - 需要研究 android 的 init.rc

- adb 默认使用 IPv6

-----

## Elaine

### 以太网压力测试问题

> https://partnerissuetracker.corp.google.com/issues/246404063  进行中

触摸屏驱动影响了 USB 以太网，在不停重启压力测试时，会出现找不到 eth0 问题。

- 临时解决方法

```c
// vim drivers/input/touchscreen/goodix_touch_gtx8/goodix_ts_i2c.c
//module_init(goodix_i2c_init);
late_initcall(goodix_i2c_init);
```

- 研究触摸屏怎么影响 usb
- 研究 usb_event 的原理

### 显示屏功率 GPIO bug

> https://jira.amlogic.com/browse/GH-3038 Wrong lcd panel power setting

