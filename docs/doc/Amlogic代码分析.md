# crg 控制器分析

## 分析 udc_bind_to_driver 函数的调用栈

```c
//fs/configfs/file.c 
//在用户层配置 usb 的时候会调用这个函数
static ssize_t configfs_write_file(struct file *file, const char __user *buf, size_t count, loff_t *ppos) {
	// 在配置 USB 时，内核会通过这个函数获取用户空间的配置信息写入到内核中
	struct configfs_buffer *buffer = file->private_data;
	len = fill_write_buffer(buffer, buf, count);
	if (len > 0)
		len = flush_write_buffer(file, buffer, len)
}
static int
flush_write_buffer(struct file *file, struct configfs_buffer *buffer, size_t count)
{
	res = buffer->attr->store(buffer->item, buffer->page, count);  // 这里就会回调 gadget_dev_desc_UDC_store 函数
}
```

```c
//drivers/usb/gadget/configfs.c
static ssize_t gadget_dev_desc_UDC_store(struct config_item *item,
		const char *page, size_t len)
{
	// 这个函数会解析 设备控制器驱动（UDC） 的信息，主要是通过 udc_name 来匹配并加入 udb_list 中
	// 最后去执行usb_gadget_probe_driver(&gi->composite.gadget_driver);
}
```

```c
//drivers/usb/gadget/udc/core.c
int usb_gadget_probe_driver(struct usb_gadget_driver *driver)
{
	// 从 udc_list 中找到相应的 udc 控制器，
	if (driver->udc_name) { 
		list_for_each_entry(udc, &udc_list, list) {
			ret = strcmp(driver->udc_name, dev_name(&udc->dev));
		}
	}
	// 找到之后将这个udc控制器 与 驱动程序绑定
	//driver->udc_name = fe320000.crgudc2 也就是 corigine usb （crg）控制器
	ret = udc_bind_to_driver(udc, driver);
}
static int udc_bind_to_driver(struct usb_udc *udc, struct usb_gadget_driver *driver)
{
	// 调用绑定实现函数
	ret = driver->bind(udc->gadget, driver);
	//启动 udc gadget
	ret = usb_gadget_udc_start(udc);  // crg_gadget_start
	// 连接或断开 USB 控制器与 USB 总线之间的连接
	usb_udc_connect_control(udc);
}
```

## crg_gadget_start

```c
//drivers/amlogic/usb/crg/crg_udc.c
static int crg_gadget_start(struct usb_gadget *g,
			struct usb_gadget_driver *driver)
{
	crg_udc = gadget_to_udc(g);  // 通过usb_gadget 找到 crg_udc
	crg_udc->gadget_driver = driver;
	// 注意这里的crg_udc 主要的作用是返回给 udc_bind_to_driver 函数中的 udc ,
	//最终给 usb_add_gadget_udc 添加（crg_udc_probe调用）
	
	g_dnl_board_usb_cable_connected();
}
int g_dnl_board_usb_cable_connected(void)
{
	 crg_udc = &crg_udc_dev;

	 uccr = crg_udc->uccr; 
	 tmp = reg_read(&uccr->portsc)  // Port Status and Control Register (PORTSC)
	 // Port Power 电源, 除非确认端口电源（PP）=（1），否则软件不能改变端口的状态
 	if (tmp & CRG_U3DC_PORTSC_PP) {
		//已经接通电源了，可以真正去启动crg_udc，  最终会调用crg_udc_start 启动 crg_udc
		crg_udc_start(crg_udc);
		// 将 device_state 改变成有线通电状态
		crg_udc->device_state = USB_STATE_POWERED;
	}
}
```

### portsc register

```c
/*portsc register*/
#define CRG_U3DC_PORTSC_CCS			BIT(0)
#define CRG_U3DC_PORTSC_PED			BIT(1)
#define CRG_U3DC_PORTSC_PP			BIT(3)  //  Port Power 电源
#define CRG_U3DC_PORTSC_PR			BIT(4)
```

> g_dnl_board_usb_cable_connected 函数中的 crg_udc_dev 是在 crg_udc_probe 函数中进行复制的

### crg_udc_probe

```c
static int crg_udc_probe(struct platform_device *pdev)
{
	crg_udc = &crg_udc_dev;
	crg_udc->gadget.name = "crg-gadget";
	crg_udc->gadget.ops = &crg_gadget_ops;
	crg_udc->connected = 0;
	// uccr 里面记录了各个寄存器
	crg_udc->uccr = crg_udc->mmio_virt_base + CRG_UCCR_OFFSET;
	
	ret = usb_add_gadget_udc(&pdev->dev, &crg_udc->gadget);  // 最终调用 usb_add_gadget_udc_release
}
```

```c
//drivers/usb/gadget/udc/core.c
// 向 udc 类驱动程序列表添加一个新的 gadget
int usb_add_gadget_udc_release(struct device *parent, struct usb_gadget *gadget,
                void (*release)(struct device *dev))
{
	//其中struct usb_gadget是用来标记一个USB设备的信息。此时USB设备的状态就能够肯定了。
	//以后启动工做队列schedule_work(&gadget->work);将状态信息给到sysfs。code
	INIT_WORK(&gadget->work, usb_gadget_state_work);
	/*
	static void usb_gadget_state_work(struct work_struct *work)
	{
		这个函数主要目的就是将当前的 state 信息写入到 sysfs 中去。这个信息能够cat出来
		 # cat ./sys/devices/platform/soc/fe320000.crgudc2/udc/fe320000.crgudc2/state
                 configured  连接
                 # cat ./sys/devices/platform/soc/fe320000.crgudc2/udc/fe320000.crgudc2/state
                  not attached
                
		sysfs_notify(&udc->dev.kobj, NULL, "state");
	}
	*/
	
	// 在USB的枚举阶段，会根据USB所处的状态调用 usb_gadget_set_state()去设置USB设备的状态。
	usb_gadget_set_state(gadget, USB_STATE_NOTATTACHED);
	udc->vbus = true;
	// vbus 设置为 true ，表示 USB 控制器与 usb 总线连接，看上面的 usb_udc_connect_control
}

// 拔出插入时都会调用这个函数
static void usb_udc_connect_control(struct usb_udc *udc)
{
	if (udc->vbus)
		usb_gadget_connect(udc->gadget)
	else
		usb_gadget_disconnect(udc->gadget);
}
```

### usb_udc_vbus_handler

另外 udc/core.c 中提供了 usb_udc_vbus_handler 接口，用于判断 connect state 来决定是否将控制器与 usb 总线连接

```c
// The udc driver calls it when it wants to connect or disconnect gadget according to vbus status
void usb_udc_vbus_handler(struct usb_gadget *gadget, bool status)
{
	struct usb_udc *udc = gadget->udc;

	if (udc) {
		udc->vbus = status;
		usb_udc_connect_control(udc);
	}
}
```

- 将控制器与 usb 总线断开连接 usb_udc_vbus_handler(&g_crg_udc->gadget, false);
- 将控制器与 usb 总线连接 usb_udc_vbus_handler(&g_crg_udc->gadget, true);


## crg_udc_start

回到 g_dnl_board_usb_cable_connected 中启动 crg_udc 的函数

```c
static void crg_udc_start(struct crg_gadget_dev *crg_udc)
{
	struct crg_uccr *uccr;
	u32 val;

	CRG_DEBUG("%s %d\n", __func__, __LINE__);

	uccr = crg_udc->uccr;

	/*****interrupt related*****/
	val = reg_read(&uccr->config1);  // Config 1 (Event) Register
	val |= (CRG_U3DC_CFG1_CSC_EVENT_EN |
			CRG_U3DC_CFG1_PEC_EVENT_EN |
			CRG_U3DC_CFG1_PPC_EVENT_EN |
			CRG_U3DC_CFG1_PRC_EVENT_EN |
			CRG_U3DC_CFG1_PLC_EVENT_EN |
			CRG_U3DC_CFG1_CEC_EVENT_EN);
	reg_write(&uccr->config1, val);
	CRG_DEBUG("config1[0x%p]=0x%x\n", &uccr->config1, reg_read(&uccr->config1));  // 0x10557b
	CRG_DEBUG("config0[0x%p]=0x%x\n", &uccr->config0, reg_read(&uccr->config0));  // 0xf3

	val = reg_read(&uccr->control);  // Control Register
	val |= (CRG_U3DC_CTRL_SYSERR_EN |
			CRG_U3DC_CTRL_INT_EN);
	reg_write(&uccr->control, val);
	/*****interrupt related end*****/

	val = reg_read(&uccr->control);
	val |= CRG_U3DC_CTRL_RUN;
	reg_write(&uccr->control, val);
	CRG_DEBUG("%s, control=0x%x\n", __func__, reg_read(&uccr->control));
}
```

### Config 1 (Event) Register

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.173ii00k96w0.webp)


### Config 0 (Device) Register

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.7b83dnug2i00.png)


----

## init_ep_info

```c
static int init_ep_info(struct crg_gadget_dev *crg_udc)
{
	// 将 ep[0] 预留出来
	crg_ep_struct_setup(crg_udc, 0, NULL);

	// 分别对 epin（1-15） 和 epout（1-15） 进行配置
	crg_ep_struct_setup(crg_udc, i * 2, name);
}
```

