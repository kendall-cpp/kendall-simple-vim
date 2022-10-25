

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

各总线除了管理 driver 外，还管理 device，通常会提供一支 API 来添加设备，如：

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

当增加新 device 的时候，bus 会轮循它的驱动列表来找到一个匹配的驱动，它们是通过 device id 和 driver 的 id_table 来进行 ”匹配” 的，主要是在 `driver_match_device() [drivers/base/base.h]` 通过 `bus->match()` 这个 callback 来让驱动判断是否支持该设备，一旦匹配成功，device 的 driver 字段会被设置成相应的 driver 指针 

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

所以，对于驱动开发者而言，我们需要关心最基本的两个步骤

- 定义 device id table
- probe() 或者 connect() 开始具体的初始化工作

![](https://gitee.com/linKge-web/PerPic/raw/master/bookImg/linux-kernel/device-driver.png)


> https://zhuanlan.zhihu.com/p/477794027


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

## hub_activate

首先 HUB_INIT, 使能 hub；其次 HUB_INIT2, 获取 hub port 状态，然后设置状态；最后 HUB_INIT3 提交 hub->urb ；然后提交 hub->events 工作至 hub_wq 队列中. 其中 hub_wq 是在 usb_hub_init() 函数中初始化的


> https://www.51cto.com/article/712072.html



