
## Korlan

### fix fct-korlan 无法找到 ip 

> issue: https://partnerissuetracker.corp.google.com/issues/247080714

- 解决方法

- 打开 CONFIG_USB_RTL8152=y

```sh
# vim arch/arm64/configs/korlan-p2_defconfig
CONFIG_USB_RTL8152=y
```

- 动态获取需要启动 hdcpcd 服务

如果要开机就启动 dhcpcd 服务，需要在 init.rc 中添加 `start dhcpcd`

USB 需要设置成 host 模式

```sh
# 第一种返回时
echo 1 > /sys/kernel/debug/usb_mode/mode  

# 第二种方式
fts -s usb_controller_type  host
reboot
```

korlan 中是用 `ifconfig -a` 命令查看

### chrome 单独编译一个模块

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/adb

mma PARTNER_BUILD=true

# test
echo 0 > /sys/kernel/debug/usb_mode/mode
```

### 提交

```
git push eureka-partner HEAD:refs/for/korlan-master

https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/260551
```

### fix adb connect 被拒绝问题

adb connect 默认是使用 IPV6 进行连接的，所以需要在 kernel 中开启 IPV6，开启方式需要在 make menuconfig 中开启。

主要可能会出现编译出错

```c
make: *** [Makefile:1159: net] Error 2
make: *** Waiting for unfinished jobs....
Fatal error: script ./build_kernel.sh aborting at line 54, command "make CLANG_TRIPLE=$clang_triple CC=$cc_clang CROSS_COMPILE=$1 ARCH=$3 -j$2 $4 CONFIG_DEBUG_SECTION_MISMATCH=y" returned 2
```

解决方法是修改 `include/linux/ipv6.h`

```c
+	__s32		accept_ra_rt_table;
	__s32		proxy_ndp;
	__s32		accept_source_route;
	__s32		accept_ra_from_local;
```

> - https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/258568
> - commit id: 201aba35948fbe8d1ca1307d46c8afec478b1803

- 测试

使用 netstat 命令查看有没有监听 5555 端口

启动 start adbd-secure

- 遇到能 adb connect ip:5555 ,但是不能 adb shell 问题

这可能是编译的 adb-secure 的问题，可以重新编译 adb-secure 并替换 ramdisk 中 sbin/adb-secure

编译方法

- chrome 单独编译一个模块

        - 如果要编译成 ipv4

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core
#vim libcutils/socket_inaddr_any_server_unix.cpp
# 修改 socket ipv4

cd abd
mma PARTNER_BUILD=true
```

-----

## Elaine

### 以太网压力测试问题 还没解决

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

### 显示屏功率 GPIO bug -- 未开始

> https://jira.amlogic.com/browse/GH-3038 Wrong lcd panel power setting

