# Korlan

## fix fct-korlan 无法找到 ip 【Done】

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

korlan 中是用 `ifconfig -a` 命令查看 ip

### chrome 单独编译一个模块

```sh
/mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core/adb

mma PARTNER_BUILD=true

# test
echo 0 > /sys/kernel/debug/usb_mode/mode
```

### 提交

```sh
git push eureka-partner HEAD:refs/for/korlan-master

# 需要关注
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/260551
commit id: 7ef11940e2f980a3e10243fce1cdb87cd80cf1d6
```

## fix adb connect 被拒绝问题 【Done】

adb connect 默认是使用 IPV6 进行连接的，所以需要在 kernel 中开启 IPV6，开启方式需要在 make menuconfig 中开启。

- 可能会出现编译出错

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

- 测试

使用 netstat 命令查看有没有监听 5555 端口

启动 start adbd-secure / start adbd

- 遇到能 adb connect ip:5555 , 但是不能 adb shell 问题

这可能是编译的 adb-secure 的问题，可以重新编译 adb-secure 并替换 ramdisk 中 sbin/adb-secure

- 编译方法

```sh
# /mnt/fileroot/shengken.lin/workspace/google_source/eureka/chrome/system/core
#vim libcutils/socket_inaddr_any_server_unix.cpp
# 修改 socket ipv4 [adb 默认是ipv6]

cd abd
mma PARTNER_BUILD=true
```

-----

# Elaine

## 以太网压力测试问题 【Done】

> https://partnerissuetracker.corp.google.com/issues/246404063  

触摸屏驱动影响了 USB 以太网，在不停重启压力测试时，会出现找不到 eth0 问题。

### 解决方法--推迟goodix

> https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/255070

```c
// vim drivers/input/touchscreen/goodix_touch_gtx8/goodix_ts_i2c.c
- module_init(goodix_i2c_init);
+ late_initcall(goodix_i2c_init);
```

### 推迟 func3

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/259656
commitId: 6b7f44b5eed0a00ef73bb94dbf5c64551fdb40a9
```


### 根据kernel patch 修复

- 讨论 (patch 链接在最后)：https://bugzilla.kernel.org/show_bug.cgi?id=214021

#### bug 解决总结

在 xhci_plat_probe 里，两个重量级的函数是 usb_create_hcd 和 usb_add_hcd , 下面我们主要分析这两个函数。

```c
hcd = usb_create_hcd(driver, &pdev->dev, dev_name(&pdev->dev));  //创建一个usb_hcd结构体，并进行一些赋值操作， usb2.0
usb_create_shared_hcd()   //创建一个 usb_hcd 结构体，usb 3.0


// 在 USB 3.0 之后，两次执行 usb_add_hcd ，第一次只是 xhci_run （set_bit(HCD_FLAG_DEFER_RH_REGISTER, &hcd->flags);）, 
// 并没有去注册 hcd，也就是没有执行 register_root_hub
// 第二次 xhci_run --> xhci_run_finished 
// 接着 register_root_hub 两个 hcd（primary_hcd 和 share_hcd）
usb_add_hcd(hcd, irq, IRQF_SHARED);  
usb_add_hcd(xhci->shared_hcd, irq, IRQF_SHARED) 

//最后通过这个函数去通知 hub。这个函数 会一直使用定时器调用自己，如果读取到 hub 有变化，而且有提交的 urb，就返回。
usb_hcd_poll_rh_status(hcd) 
//会面就会去对 hub_event 进行处理
```

同时需要注意 `#define HCD_FLAG_DEFER_RH_REGISTER     12` , kernel patch 中设置的是第 8 位 bit，但是在 elaine-kernel 的版本中第 8 位已经被占用，因此改成第 12 位，否则 usb2 的 hcd 永远无法 register 。


#### 最终提交

```
https://eureka-partner-review.googlesource.com/c/amlogic/kernel/+/262595
commit id : 934882f98b37c0485de4850f7f1f7001d6c3c269
issue: https://partnerissuetracker.corp.google.com/issues/246404063#comment2
```

---

## 显示屏功率 GPIO bug 【None】

> https://jira.amlogic.com/browse/GH-3038 Wrong lcd panel power setting

---

# C3 Camera 【Doing】

