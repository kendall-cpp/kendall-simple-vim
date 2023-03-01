<!-- TOC -->

- [bus,driver,device 框架](#busdriverdevice-框架)
  - [注册](#注册)
  - [device 和 driver绑定](#device-和-driver绑定)
- [USB主控制器 HCD 分析](#usb主控制器-hcd-分析)
  - [概述](#概述)
  - [USB 主控制器驱动](#usb-主控制器驱动)
    - [usb主机控制器硬件情况](#usb主机控制器硬件情况)
    - [dwc](#dwc)
    - [xhci](#xhci)
- [USB-Hub](#usb-hub)
  - [usb\_hub\_init](#usb_hub_init)
  - [hub\_configure](#hub_configure)
  - [hub\_activate](#hub_activate)
- [USB整体框架](#usb整体框架)

<!-- /TOC -->

kernel 分为两个模块，一个是 core：cpu ，中断，进程，内存几大管理，提供系统呼叫，另一个是 driver，driver 各类结构成为 "子系统" ，比如：block 子系统，net 子系统，usb 子系统等。另外，微内核和宏内核的区别就是 驱动是否放在内核。

# bus,driver,device 框架

linux 的外围设备驱动，都是通过 bus+driver+device 来管理的，外设都是通过总线与 CPU 通讯的，kernel 会实现各种总线的规范以及设备管理（设备检测，驱动绑定等），驱动程序只需要注册自己的驱动，实现对设备的读写控制即可。

这类的驱动可以分为两部分：总线（bus）子系统 + 驱动模块

驱动程序的流程大致如下：

- bus_register(xx)

kernel 里面的各 bus 子系统（比如：serio，usb，pci，...) 会使用这个函数来注册自己。

- driver_reister(xx)

驱动模块使用这个函数来向总线系统注册自己，这样驱动模块就只需要关注相应的 driver 接口的实现就可以了，通常，bus 子系统会对 driver_register 来进行封装。比如：

```c
serio 	提供 serio_register_driver()
usb 	提供 usb_register_driver()
pci		提供 pci_register_driver()
```

- registe_device(xx)

各总线除了管理 driver 外，还管理 device，通常会提供一些 API 来添加设备，如：

input_register_device, serio_add_port， 实现上都是通过一个链表对设备进行管理，通常是在初始化或者 probe 的时候，添加设备。

设备(device)指的是具体实现总线协议的物理设备，如对 serio 总线而言，i8042 就是它的一个设备，而该总线连接的设备(鼠标，键盘)则是一个 serio driver。

## 注册

bus.c 和 driver.c 分别对 bus,driver 和 device 进行管理，提供注册 bus, driver 和查找 device 功能。

- `bus_register(*bus)` 这个函数会生成两个 list，用来保存设备和驱动。

```c
INIT_LIST_HEAD(&priv->interfaces);
klist_init(&priv->klist_devices, klist_devices_get, klist_devices_put);
klist_init(&priv->klist_drivers, NULL, NULL);

//priv 是 struct subsys_private 定义在 driver/base/base.h
```

- 注册驱动 `driver_register(*drv)` 实际上就是调用 `bus_add_driver(*drv)` 把 drv 添加到 klist_drivers 

```c
klist_add_tail(&dev->p->knode_bus, &bus->p->klist_devices);
```

- 同理注册 device ，也是通过 `bus_add_device(*dev)`，添加到 klist_devices:

```c
klist_add_tail(&dev->p->knode_bus, &bus->p->klist_devices);
```

以 `hid_bus_type` 为例，执行 `bus_register(&hid_bus_type)` 后， `hid_bus_type->p->klist_devices` 和 `hid_bus_type->p->klist_klist_drivers` 这两个 list 会被初始化，为后面的 driver 和 device 注册做准备.

## device 和 driver绑定

当增加新 device 的时候，bus 会轮循它的驱动列表来找到一个匹配的驱动，它们是通过 device id 和 driver 的 id_table 来进行 ”匹配” 的，主要是在 `driver_match_device() [drivers/base/base.h]` 通过 `bus->match()` 这个 callback 来让驱动判断是否支持该设备，一旦匹配成功，device 的 driver 字段会被设置成相应 device 的 driver 指针 

```c
static inline int driver_match_device(struct device_driver *drv,
                   struct device *dev) 
{                                                           
    return drv->bus->match ? drv->bus->match(dev, drv) : 1;     
} 
```

然后 callback 这个 driver 对应的 probe 或者 connect 函数，进行一些初始化操作。同理，当增加新的 driver 时， bus 也会执行相同的动作，为驱动查找设备。因此，绑定发生在两个阶段：

1: **驱动找设备**，发生在driver向bus系统注册自己时候，函数调用链是：

> driver_register --> bus_add_driver --> driver_attach() `[base/dd.c]` －－ 将轮循 device 链表，查找匹配的 device 。

2: **设备查找驱动**，发生在设备增加到总线的的时候，函数调用链是：

> device_add --> bus_probe_device --> device_initial_probe --> device_attach －－ 将轮循 driver 链表，查找匹配的 driver。

匹配成功后，系统继续调用 `driver_probe_device()` 来 callback `drv->probe(dev)` 或者 `bus->probe(dev) -->drv->connect()`，再 probe 或者 connect 函数里面，驱动开始实际的初始化操作。因此，`probe()` 或者 `connect()` 是真正的驱动'入口'。


![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/driver-device.png)


> https://zhuanlan.zhihu.com/p/477794027

----



# USB主控制器 HCD 分析

## 概述

USB 的主控制器（HCD）有多种不同的类型，分别有 OHCI， UHCI，EHCI，和 XHCI

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221028155013.png)

USB 采用树形拓扑结构，主机侧和设备侧的 USB 控制器分别称为主机控制器(Host Controller)和 USB 设备控制器(UDC)，每条总线上只有一个主机控制器，负责协调主机和设备间的通信，设备不能主动向主机发送任何消息。

## USB 主控制器驱动

### usb主机控制器硬件情况

USB Host 带有 Root Hub，第一个 USB 设备是一个根集线器（Root Hub)，它控制连接着 USB 总线上的其他设备。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/202210291406103.png)

**大致概述**：首先把根集线器（root hub) 作为一个设备添加到 usb 总线的设备队列里，同时，从总线的驱动队列中查找是否有可以支持这个设备（root hub设备）的驱动程序，如果查找到，就可以通过相应的指针把它们都关联起来，如果找不到这个驱动程序，那么 root hub 就无法正常工作了，只能在总线的设备队列中等待有驱动安装时，再匹配是否 OK，如果一直没有对应的驱动，那么这条总线也就没有办法挂载其他的设备。

一旦 Root hub 匹配成功驱动后，就会循环运行一个守护进程，用来检测和发现 hub 的端口是否有设备插入或者拔出。

### dwc

> 先简单概述一下 dwd

dwc 作为一个 platform device ,这些信息由设备树解析，与驱动匹配后执行 dwc3_probe（`drivers/usb/dwc3/core.c`）。

```c
dwc3_probe
  ==> dwc3_core_init_mode(dwc)
    ==> dwc3_host_init(dwc)
      ==> xhci = platform_device_alloc("xhci-hcd", PLATFORM_DEVID_AUTO);
      ==> platform_device_add(xhci); 
```

### xhci

xhci 作为一个platform device 注册之后，与驱动匹配后执行 xhci_plat_probe (`drivers/usb/host/xhci-plat.c`).


这里主要以一个 bug 开始去分析这部分代码

```sh
# 在不断 reboot 测试时，发现 USB 以太网会出现概率性无法工作为题，出现问题时报错如下：
[    4.991963@3] usb usb1-port2: couldn't allocate usb_device
```

这个问题的最根本原因是：内核为了兼容 usb2 和 usb3 需要注册两个 hcd (primary_hcd and shared_hcd) ，但是一旦注册了主 roothub，可能在 xhci 运行之前就处理了端口状态的变化，导致未检测到 USB 设备。（看完下面分析再来看这个问题）

- xhci_plat_probe 

[点击查看代码](https://elixir.bootlin.com/linux/v4.9.331/source/drivers/usb/host/xhci-plat.c#L138)

当然你也可以直接 git clone kernel 代码代理本地查看更方便

```sh
git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
或者： git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
```


首先从 xhci_plat_probe 函数开始，该函数主要是创建和注册 hcd。

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

----

# USB-Hub


在 usb_hub_init 函数中完成了注册 hub 驱动，并且利用函数 alloc_workqueue 创建一个工作队列。

USB 设备是热插拔的，因此在 hub_probe 函数中调用 hub_configure 函数来配置 hub，这个函数主要是利用 usb_alloc_urb 函数来分配一个 urb，利用 usb_fill_int_urb 来初始化这个 urb 结构，包括 hub 的终点服务程序 hub_irq 和 查询周期等。

每当有设备连接到 USB 接口时，USB 总线在查询 hub 状态信息的时候会触发 hub 的中断服务程序 hub_irq ，在函数中置位 event_bits , 运行工作队列。进入 hub_event 函数，该函数用来处理端口变化的事件。然后通过一个 for 循环来检测每个端口的状态信息。利用 usb_port_status 获取端口信息，如果发生变化就调用 hub_port_connect_change 函数来配置端口等。

## usb_hub_init

```c
int usb_hub_init(void)
{
    if (usb_register(&hub_driver) < 0) {   // 注册 hub_driver ，运行 hub_probe
        printk(KERN_ERR "%s: can't register hub driver\n",
            usbcore_name);
        return -1;
    }

    /*   
    * 工作队列需要是可冻结的，以避免干扰usb持续的端口切换。
    * 否则它可能会看到全速设备在EHCI控制器把端口交给全速控制器之前就消失了
    */
    hub_wq = alloc_workqueue("usb_hub_wq", WQ_FREEZABLE, 0);
    if (hub_wq)
        return 0;

    /* Fall through if kernel_thread failed */
    usb_deregister(&hub_driver);
    pr_err("%s: can't allocate workqueue for usb hub\n", usbcore_name);

    return -1;
}
```
## hub_configure

接着 hub_probe --> hub_configure 

hub_configure 配置不同的 hub，但是 linux 最多只能支持 31 个接口

```c
get_hub_descriptor(hdev, hub->descriptor);  获取整个 hub 描述符。

usb_get_status(hdev, USB_RECIP_DEVICE, 0, &hubstatus);   返回设备、接口或端点状态。通常只关注设备是否自供电，或是否启用了远程唤醒功能。或者一个批量或中断端点是否被停止(“stall”)。

UHCI 必须要知道 HUB 的端口的一些连接状态，因此，需要HUB周期性的上报它的端口连接状态. 这个 URB 就是用来做这个用途的。 UHCI 周期性的发送 IN 方向中断传输传输给 HUB . HUB 就会通过这个 URB 将端口信息发送给 UHCI.那这个轮询周期是多长呢?

它的调度周期是由 endpoint 的 bInterval 字段所决定的.

usb_fill_int_urb(hub->urb, hdev, pipe, *hub->buffer, maxp, hub_irq,
          hub, endpoint->bInterval);    //填充urb,完成之后调用 hub_irq 函数，
                        //再通过 kick_hub_wq --> queue_work(hub_wq, &hub->events)) 执行 hub_event

ret = usb_hub_create_port_device(hub, i + 1); 
//创建hub的端点设备，比如/sys/devices/platform/soc@0/38100000.usb/xhci-hcd.0.auto/usb1/1-0:1.0/usb1-port1

hub_activate   // 主要是启动hub，我们这里传入的参数是HUB_INIT
```

hub_configure 注册了中断，一旦接入新的usb设备就会调用 hub_irq 

## hub_activate

首先 HUB_INIT, 使能 hub；其次 HUB_INIT2, 获取 hub port 状态，然后设置状态；最后 HUB_INIT3 提交 hub->urb ；然后提交 hub->events 工作至 hub_wq 队列中. 其中 hub_wq 是在 usb_hub_init() 函数中初始化的


> https://www.51cto.com/article/712072.html

----

# USB整体框架

USB 驱动分为主机侧和设备侧，主机侧和设备侧的 USB 控制器分别称为主机控制器( Host Controller )和 USB 设备控制器(UDC)。USB 核心层向上下提供编程接口，维护整个系统的 USB 信息，完成热插拔控制，数据传输控制。

- 主机侧：

从上图看，我们需要实现两个驱动，USB主机控制器驱动和USB设备驱动。

USB主机控制器驱动：控制插入的USB设备

USB设备驱动：控制具体USB设备和主机如何通信

- 设备侧：

设备侧也需要实现两部分驱动，UDC驱动和Gadget Function驱动。

UDC驱动：控制USB设备和主机的通信

Gadget Function驱动：控制USB设备功能的实现

其中 Compsite Framwork 提供了一个通用的 sb_gadget_driver 模板，包括各种方法供上层 Function driver 使用。（`driver/usb/gadget/compsite.c`）

- USB设备驱动：用于和枚举到的USB设备进行绑定，完成特定的功能。

- USB Core：用于内核USB总线的初始化及USB相关API，为设备驱动和HCD的交互提供桥梁。

- USB主机控制器 HCD：完成主机控制器的初始化以及数据的传输，并监测外部设备插入，完成设备枚举。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/202212172254392.png)


usb Function driver 可以细分为 legacy 和 funtions

- legacy: 整个 gadget 设备驱动入口，位于 drivers/usb/gadget/legacy , 里面给出了常用 usb 类设备的驱动 sample,  其作用就是配置 USB 设备描述符信息，支持的协议等，提供一个 usb_composite_driver , 然后注册到 composite 层

- function： 各种 usb 之类设备功能驱动，位于 drivers/usb/gadget/function， 里面给出了对应的 sample , 其作用是配置 usb 之类协议的接口描述符以及其他之类协议，比如 uvc 协议，hid协议等。

> **注意，一个 compsite 设备对应一个或者多个 function ，也就是对应多个 function driver**。



4