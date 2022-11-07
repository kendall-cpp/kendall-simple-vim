
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

hub_configure 注册了中断，一旦接入新的usb设备就会调用 hub_irq ,

## hub_activate

首先 HUB_INIT, 使能 hub；其次 HUB_INIT2, 获取 hub port 状态，然后设置状态；最后 HUB_INIT3 提交 hub->urb ；然后提交 hub->events 工作至 hub_wq 队列中. 其中 hub_wq 是在 usb_hub_init() 函数中初始化的


> https://www.51cto.com/article/712072.html

----

# USB主控制器 HCD 分析

## 概述

USB 的主控制器（HCD）有多种不同的类型，分别有 OHCI， UHCI，EHCI，和 XHCI

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221028155013.png)

USB 采用树形拓扑结构，主机侧和设备侧的 USB 控制器分别称为主机控制器(Host Controller)和 USB 设备控制器(UDC)，每条总线上只有一个主机控制器，负责协调主机和设备间的通信，设备不能主动向主机发送任何消息。

## USB 主控制器驱动

### usb主机控制器硬件情况

USB Host 带有 Root Hub，第一个 USB 设备是一个根集线器（Root Hub)，它控制连接在 USB 总线上的其他设备。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/202210291406103.png)

首先把根集线器（root hub) 作为一个设备添加到 usb 总线的设备队列里，同时，从总线的驱动队列中查找是否有可以支持这个设备（root hub设备）的驱动程序，如果查找到，就可以通过相应的指针把它们都关联起来，如果找不到这个驱动程序，那么 root hub 就无法正常工作了，只能在总线的设备队列中等待有驱动安装时，再匹配是否 OK，如果一直没有对应的驱动，那么这条总线也就没有办法挂载其他的设备。

一旦 Root hub 匹配成功驱动后，就会循环运行一个守护进程，用来检测和发现 hub 的端口是否有设备插入或者拔出。

**大致流程如下**

> 可以参考： https://www.cnblogs.com/image-eye/arcive/2012/01/31/2333236.html

- xhci_plat_probe
  
```c
xhci_plat_init
  usb_xhci_driver
    xhci_plat_probe  //主要是创建和注册 hcd
      usb_create_hcd(driver, &pdev->dev, dev_name(&pdev->dev))  //创建一个usb_hcd结构体，并进行一些赋值操作， usb2.0
        usb_create_shared_hcd()
      hcd_to_xhci(hcd)
        return (struct xhci_hcd *) (primary_hcd->hcd_priv);  //取hcd的primary_hcd，并转成xhci_hcd，主机控制器的私有数据被存储在hcd_priv[0]这个结构体的末尾
      usb_create_shared_hcd()   //创建一个 usb_hcd 结构体，usb 3.0
      //上面创建的两个 hcd 是一个环形链表，usb2.0 的 hcd 是 primary_hcd，他们都是用同一 address0_mutex
      usb_add_hcd(hcd, irq, IRQF_SHARED);  
      usb_add_hcd(xhci->shared_hcd, irq, IRQF_SHARED)  
```

usb_create_hcd 和 usb_add_hcd 分别用于创建和将 usb_hcd 添加到系统中。在这里，有两个 usb_hcd，一个是 main_hcd (或者 primary_hcd )，一个是 shared_hcd

- usb_add_hcd

```c
usb_hcd_request_irqs  // 申请一个hcd中断定时器
  request_irq --> usb_hcd_irq(中断回调函数)
    // 当外部产生终端，比如 usb 口插入设备，就会触发 usb_hcd_irq

hcd->driver->start(hcd)  //.start = xhci_plat_start; xhci_run;  实际是调用 xhci_run ， 启动 xhci host controller
  xhci_run
    //这个函数完成usb2.0 xhci 的启动
    xhci_run_finished
      //这个函数完成 usb3.0 xhci 的启动
register_root_hub()
usb_hcd_poll_rh_status()  //通知 hub。这个函数 会一直使用定时器调用自己，如果读取到 hub 有变化，而且有提交的 urb，就返回。


//hcd->shared_hcd 总是创建并注册到 usb-core 。 如果由于某些原因禁用了 USB3 下行端口，则没有 roothub 端口
//https://lkml.iu.edu/hypermail/linux/kernel/2108.3/03119.html
//“HCD_FLAG_DEFER_RH_REGISTER”设置为 hcd->flags 以延迟 在 usb_add_hcd() 中注册主 roothub。
//这将确保两者 主 roothub 和辅助 roothub 将与 第二个HCD。这是检测冷插拔 USB 设备所必需的 
//在某些 PCIe USB 卡中（例如连接到 AM64 EVM 的 Inateck USB 卡 或 J7200 EVM）。

```

---

xhci_plat_probe 里，两个重量级的函数是 usb_create_hcd 和 usb_add_hcd ,用了创建 usb_hcd 和将 usb_hcd 添加到系统中。

```c
usb_add_hcd  // 通用HCD结构初始化和注册
  usb_register_bus // 通过usb core 注册USB主机控制器， bus: 指向要注册的总线的指针
    usb_notify_add_bus  //发送添加总线通知
    usb_alloc_dev  // 给 root hub 分配空间
    device_set_wakeup_capable(&rhdev->dev, 1);  //唤醒标志init默认为“一切正常,如果需要，驱动程序可以在reset()中覆盖它，同时记录整个控制器的系统唤醒能力。
    set_bit(HCD_FLAG_RH_RUNNING, &hcd->flags);  // 在注册根集线器之前，HCD_FLAG_RH_RUNNING并不重要。但是由于控制器随时可能死亡，让我们在接触硬件之前初始化标志。

    //xHCI规范说我们可以得到一个中断，如果HC在某种情况出现了错误，我们可能会从事件环中获取坏数据。这个中断不是用来探测插入了设备的
    if (usb_hcd_is_primary_hcd(hcd) && irqnum)  {
        retval = usb_hcd_request_irqs(hcd, irqnum, irqflags);  // 申请中断，中断处理函数usb_hcd_irq，实际调用 xhci_irq
    if (retval)
        goto err_request_irq;
    }

    retval = hcd->driver->start(hcd); // 实际是调用 xhci_run ， 启动 xhci host controller


    retval = register_root_hub(hcd); //注册一个root hub

// ---------------
    //如果驱动请求roothub中断传输,会用一个定时器轮询;否则由驱动在事件发生时调用 usb_hcd_poll_rh_status()。
    if (hcd->uses_new_polling && HCD_POLL_RH(hcd))
        usb_hcd_poll_rh_status(hcd);
    //USB 2.0规范说256毫秒。这已经足够接近了，如果HZ是100，也不会超过这个限制。其中的数学运算比预期的要复杂，
    //这是为了确保用于USB设备的所有定时器同时启动，以便在两者之间给CPU一个休息时间
```

- usb_hcd_poll_rh_status  

usb_hcd_poll_rh_status 关系到一个usb设备插入的时候，如何通知 hub。这个函数 usb_hcd_poll_rh_status 会一直使用定时器调用自己，如果读取到 hub 有变化，而且有提交的 urb，就返回。

 
```c
void usb_hcd_poll_rh_status(struct usb_hcd *hcd)
{
    length = hcd->driver->hub_status_data(hcd, buffer); //这里会调用xhci_hub_status_data读取roothub的寄存器，返回数据buffer和length
    if (length > 0) {
        /* try to complete the status urb */
        spin_lock_irqsave(&hcd_root_hub_lock, flags);
        urb = hcd->status_urb;
        if (urb) { //如果已经提交了获取状态的urb, 将状态值拷贝进入urb,并把urb giveback
            clear_bit(HCD_FLAG_POLL_PENDING, &hcd->flags);
            hcd->status_urb = NULL;
            urb->actual_length = length;
            memcpy(urb->transfer_buffer, buffer, length); 
            usb_hcd_unlink_urb_from_ep(hcd, urb); //从它的端点队列中移除一个URB
            usb_hcd_giveback_urb(hcd, urb, 0); 
        } else { //若此时没有已经提交的urb,则设置poll_pending标志
            length = 0;
            set_bit(HCD_FLAG_POLL_PENDING, &hcd->flags);
        }
        spin_unlock_irqrestore(&hcd_root_hub_lock, flags);
    }

    // 确保用于USB设备的所有定时器同时启动，以便在两者之间给CPU一个休息时间, USB 2.0 规范说256毫秒
    if (hcd->uses_new_polling ? HCD_POLL_RH(hcd) : //这里hcd->uses_new_polling=1  HCD_POLL_RH(hcd)如果不等于0，会一直调用mod_timer
        (length == 0 && hcd->status_urb != NULL)) 
        //此时开启rh_timer.rh_timer的处理函数rh_timer_func,实际就是usb_hcd_poll_rh_status。
        mod_timer (&hcd->rh_timer, (jiffies/(HZ/4) + 1) * (HZ/4));
}
```

### xHCI驱动

usb/host/xhci-plat.c

- xhci_plat_probe

```c
usb_create_hcd(driver, &pdev->dev, dev_name(&pdev->dev));  //创建一个usb_hcd结构体，并进行一些赋值操作， usb2.0(main_hcd)

xhci->shared_hcd = usb_create_shared_hcd(driver, &pdev->dev,dev_name(&pdev->dev), hcd); // 创建usb 3.0 的 hcd, 对应usb3.0及以上(shared_hcd)。

ret = usb_add_hcd(hcd, irq, IRQF_SHARED);  //完成通用HCD结构初始化和注册，这里是usb2.0
ret = usb_add_hcd(xhci->shared_hcd, irq, IRQF_SHARED); //完成通用HCD结构初始化和注册，这里是usb3.0
```

----

> http://blog.chinaunix.net/uid-2605131-id-5768759.html

xhci为了向下兼容，集成了两个 roothub，一个对应 usb2.0(main_hcd)，一个对应usb3.0及以上(shared_hcd)。有两个usb_hcd，一个是main_hcd(或者primary_hcd)，一个是shared_hcd

> 参考： https://blog.csdn.net/zoosenpin/article/details/37766561

一个xHCI会注册2个 host，一个是usb1（LS/FS/HS），另一个是usb2（SS-- SuperSpeed 相当于 usb3.0）。

USB2.0接口标准中 ，USB1.1是12Mbps，新的USB2.0标准将USB接口速度划分为三类，分别是传输速率在25Mbps-400 Mbps （最大480 Mbps）的High-speed接口（简称HS） ；传输速率在500Kbps-10Mbps（最大12Mbps）的Full-speed接口（简称FS）；传输速率在10kbps-400 100kbps （最大1.5Mbps）的Low-speed接口（简称LS）。






----

参考： https://www.cnblogs.com/wen123456/p/14281912.html
