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
	// 最后去执行 usb_gadget_probe_driver(&gi->composite.gadget_driver);
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
	// cat /sys/kernel/config/usb_gadget/amlogic/UDC  ====>> fe320000.crgudc2
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
		这个函数主要目的就是将当前的 state 信息写入到 sysfs 中去。这个信息能够 cat 出来
		 # cat ./sys/devices/platform/soc/fe320000.crgudc2/udc/fe320000.crgudc2/state
                 configured  连接
                 # cat ./sys/devices/platform/soc/fe320000.crgudc2/udc/fe320000.crgudc2/state
                  not attached
                
		sysfs_notify(&udc->dev.kobj, NULL, "state");
	}
	*/
	
	// 在USB的枚举阶段，会根据USB所处的状态调用 usb_gadget_set_state() 去设置USB设备的状态。
	usb_gadget_set_state(gadget, USB_STATE_NOTATTACHED);
	udc->vbus = true;
	// vbus 设置为 true ，表示 USB 控制器与 usb 总线连接，看上面的 usb_udc_connect_control
}

// 拔出/插入 时都会调用这个函数
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

	sprintf(name, "ep%din", i);
	// 分别对 epin（1-15） 和 epout（1-15） 进行配置
	crg_ep_struct_setup(crg_udc, i * 2, name);
}

static void crg_ep_struct_setup(struct crg_gadget_dev *crg_udc,
	u32 DCI, const char *name)
// 这里的 DCI 就是第几个 ep , 其值为 0 ， 2 ~ 31
```

配置好所有的 ep 端点后就开始初始化 ep0 , 并初始化传输环 DQPTR 和 DCS ， 当启用了设置事件生成时，软件就不能再发次这个命令

**注意：**

在启用设置事件生成之前，接收到的设置请求将存储在内部，存储的设置不会受到初始化 EP0 命令的影响。

```c
static int init_ep0(struct crg_gadget_dev *crg_udc)
{
	struct crg_udc_ep *udc_ep_ptr = &crg_udc->udc_ep[0];
	/* setup transfer ring */
	if (!udc_ep_ptr->tran_ring_info.vaddr) {
		u32 ring_size = CRGUDC_CONTROL_EP_TD_RING_SIZE;  // 16
		len = ring_size * sizeof(struct transfer_trb_s);
		// 分配 dma 内存给传输环
		vaddr = dma_alloc_coherent(crg_udc->dev, len,
				&dma, GFP_KERNEL);
	}

	/*设置上下文相关操作*/
	cmd_param0 = (lower_32_bits(udc_ep_ptr->tran_ring_info.dma) &
			CRG_CMD0_0_DQPTRLO_MASK) |
			CRG_CMD0_0_DCS(udc_ep_ptr->pcs);
	cmd_param1 = upper_32_bits(udc_ep_ptr->tran_ring_info.dma);	

	// 发出命令
	crg_issue_command(crg_udc, CRG_CMD_INIT_EP0, cmd_param0, cmd_param1)

	// 改变这个 ep 的状态  ep_state
	udc_ep_ptr->ep_state = EP_STATE_RUNNING;
}
```

ep 端点基于传输环进行工作，主要的工作形式是通过 “控制命令” ， `crg_issue_command` 这个函数是发出控制命令实现函数。

### 传输环

软件使用一个传输环来为**单个 USB 端点**安排工作项目。传输环被组织为传输描述符（TD）数据结构的循环队列，其中每个传输描述符定义一个或多个数据缓冲区，用来缓存 USB 数据的传入和传输 。传输环被 xHC 视为只读环。

### Issuing Command

要发出命令，软件首先要设置命令参数（命令类型，上下文操作），然后写入命令控制寄存器。

如果在写入命令控制寄存器时声明（asserted）了 IOC 位，那么软件就会去等待这个命令去生成控制事件，这个事件是由【设备控制器】生成的。否则，软件会轮询去等待这个命令活动位 IOC ，知道它取消断言 （de-asserted）

**建议软件轮询命令活动位，而不是为以下命令设置 IOC：**

- Initialize EP0
- Update EP0 Config
- Set Address
- Reset Seqnum
- Force Flow Control

#### Command Types

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.4vyi1regomq0.webp)

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.30q5ocbutmg0.webp)

### crg_issue_command 发布命令函数

```c
static int crg_issue_command(struct crg_gadget_dev *crg_udc
		enum crg_cmd_type type, u32 param0, u32 param1)
{
	tmp = reg_read(&uccr->control);
	// 如果已经设置这个命令事件，那么就不能再次发出这个命令
	if (tmp & CRG_U3DC_CTRL_RUN)
		check_complete = true;
}
```

## crg_gadget_irq_init

Corigine USB 主要的工作都是在这个函数中完成的，这个函数最终会调用 crg_gadget_handle_interrupt 完成中断事件逻辑。

### crg_gadget_handle_interrupt

```c
int crg_gadget_handle_interrupt(struct crg_gadget_dev *crg_udc)
{
	if (tmp_status & CRG_U3DC_STATUS_EINT) {
		for (i = 0; i < CRG_RING_NUM; i++) // CRG_RING_NUM = 1
			process_event_ring(crg_udc, i);  // 处理事件环， 见下面 process_event_ring 分析
	}

	// 重新连接， crg_udc_reinit 函数中进行了初始化
	if (crg_udc->device_state == USB_STATE_RECONNECTING &&
			crg_udc->portsc_on_reconnecting == 1 &&
			is_event_rings_empty(crg_udc)) {  // 事件环 是空的
		crg_udc->portsc_on_reconnecting = 0;  // 在处理事件过程中是否将 device_state 设置为 重新连接 的标志
		crg_handle_port_status(crg_udc);   // 重新处理端口状态
	}

	 // 重新连接，但是已经初始化完并且端口状态处理完了，这时候可以开始准备 enable_setup crg_udc 
	 // 这时候 crg_udc->setup_status = WAIT_FOR_SETUP;
	 // 每次插入 USB 启动 UDC 时就会调用这里
	if (crg_udc->device_state == USB_STATE_RECONNECTING &&
		crg_udc->connected == 1) {
		CRG_DEBUG("check if ready for setup\n");
		prepare_for_setup(crg_udc);
		// crg_issue_command 发送控制命令
		// enable_setup enable 事件 enable_setup_event （改变事件寄存器 uccr->config1 ）
	}
}
```

<strong><font color="orange" size="4">
crg_udc->connected 默认是 0
</font></strong>

- 在 `crg_handle_port_status` 处理完之后会设置 crg_udc connected 为 1
- 在执行了 `crg_udc->gadget_driver->disconnect` 之后会将 crg_udc connected 为 0

#### usb_device_state

```c
enum usb_device_state {
	/* NOTATTACHED isn't in the USB spec, and this state acts
	 * the same as ATTACHED ... but it's clearer this way.
	 */
	USB_STATE_NOTATTACHED = 0,

	/* chapter 9 and authentication (wireless) device states */
	USB_STATE_ATTACHED,		// 默认状态
	USB_STATE_POWERED,			/* wired */
	USB_STATE_RECONNECTING,			/* auth */
	USB_STATE_UNAUTHENTICATED,		/* auth */
	USB_STATE_DEFAULT,			/* limited function */
	USB_STATE_ADDRESS,
	USB_STATE_CONFIGURED,			/* most functions */
	USB_STATE_SUSPENDED
/*
注意：实际上有四种不同的 SUSPENDED 状态，
当 SOF 令牌再次流动时分别返回到 POWERED 、DEFAULT 、ADDRESS 或 CONFIGURED 。 
在此级别上，L1 和 L2 挂起状态之间没有区别。 （L2 是原始 USB 1.1 挂起。）；
*/
```

#### usb_device_state 改变位置

- crg_udc_ep_enable : crg_udc->device_state = USB_STATE_CONFIGURED;
- crg_udc_ep_disable : crg_udc->device_state = USB_STATE_ADDRESS;
- crg_udc_shutdown : crg_udc->device_state = USB_STATE_ATTACHED;
- crg_udc_remove :  crg_udc->device_state = USB_STATE_ATTACHED;
- crg_udc_reinit : crg_udc->device_state = USB_STATE_RECONNECTING
- crg_udc_reset : crg_udc->device_state = USB_STATE_ATTACHED;
- crg_gadget_stop : crg_udc->device_state = USB_STATE_ATTACHED;
- set_address_cmpl : 
  - crg_udc->device_state = USB_STATE_ADDRESS;
  -  crg_udc->device_state = USB_STATE_DEFAULT;
- crg_handle_setup_pkt : crg_udc->device_state = USB_STATE_CONFIGURED;
- g_dnl_board_usb_cable_connected : crg_udc->device_state = USB_STATE_POWERED;
- crg_handle_port_status : 
  - crg_udc->device_state = USB_STATE_POWERED;
  - crg_udc->device_state = USB_STATE_ATTACHED;
- enable_setup : crg_udc->device_state = USB_STATE_DEFAULT;

### process_event_ring

```c
int process_event_ring(struct crg_gadget_dev *crg_udc, int index)
{
	struct crg_uicr *uicr = crg_udc->uicr[index];  // crg_uicr 记录相关寄存器

	// 去除事件包并处理事件
	udc_event = &crg_udc->udc_event[index];
	while (udc_event->evt_dq_pt) {
		ret = crg_udc_handle_event(crg_udc, event);   // 处理这个事件的 trb

	    	// 如果是 链接 TRB （事件环的最后一个）
		if (event == udc_event->evt_seg0_last_trb)
			//改变消费周期状态
			udc_event->CCS = udc_event->CCS ? 0 : 1 // Consumer Cycle State 消费周期状态
			udc_event->evt_dq_pt = udc_event->event_ring.vaddr;
		} else {
		udc_event->evt_dq_pt++;   // 处理下一个trb
		}
	}
	/* update dequeue pointer 更新出队指针 （erdp） */
}
```

<strong><font color="orange" size="4">
struct crg_uicr
</font></strong>

```c
// 8.7.23  Interrupt Management Register (IMAN)
// 8.7.24  Interrupter Moderation Register (IMOD)
// 8.7.26 Event Ring Segment Table Base Address Register (ERSTBA)
// 8.7.27 Event Ring Dequeue Pointer Register (ERDP)
struct crg_uicr {               
        u32 iman;   // Interrupt Management Register  中断寄存器
			/*
			CRG_U3DC_IMAN_INT_PEND : 此标志指定中断器是否能够生成中断。
			CRG_U3DC_IMAN_INT_EN : 此标志表示中断器的当前状态
			*/
        u32 imod;   // Interrupter Moderation Register  中断器审核寄存器（IMOD）
        u32 erstsz; //事件环段表大小寄存器
        u32 resv0;
        //事件环段寄存器表基地址
        u32 erstbalo; /*0x10*/  // out
        u32 erstbahi;		// in
        // 事件环出队列指针寄存器 (ERDP)
        u32 erdplo;		// out
        u32 erdphi;		// in
};
```

### crg_udc_handle_event

```c
int crg_udc_handle_event(struct crg_gadget_dev *crg_udc,
			struct event_trb_s *event)
{
  switch (GETF(EVE_TRB_TYPE, event->dw3)) {
  case TRB_TYPE_EVT_PORT_STATUS_CHANGE:  // Port Status Change Event TRB
	// 这里就要设置端口的状态
	ret = crg_handle_port_status(crg_udc);

  case TRB_TYPE_EVT_TRANSFER: // 传输事件
	// 处理传输事件
	crg_handle_xfer_event(crg_udc, event);

  case TRB_TYPE_EVT_SETUP_PKT:  // 安装类型的包
	crg_handle_setup_pkt(crg_udc, setup_pkt, setup_tag);
  }
}
```

### crg_handle_xfer_event

```c
int crg_handle_xfer_event(struct crg_gadget_dev *crg_udc,
			struct event_trb_s *event)
{
	u8 DCI = GETF(EVE_TRB_ENDPOINT_ID, event->dw3);
	struct crg_udc_ep *udc_ep_ptr = &crg_udc->udc_ep[DCI];  // 有音频数据来时 DCI = 5

	// 获取当前 ep 的状态
	get_ep_state(crg_udc, DCI) == EP_STATE_DISABLED)

	comp_code = GETF(EVE_TRB_COMPL_CODE, event->dw2);  //  TRB 的完成状态
	// 需要保证这个 ep 的状态不是 STOPPED/HALTED/DISABLED 才能够出队
	update_dequeue_pt(event, udc_ep_ptr);

	//请求出队
	if (is_request_dequeued(crg_udc, udc_ep_ptr, event))

	// 再次获取 TRB 完成状态
	comp_code = GETF(EVE_TRB_COMPL_CODE, event->dw2);
	switch (comp_code) {
	case CMPL_CODE_SUCCESS:

	case CMPL_CODE_SHORT_PKT:  // 这表明主机发送的数据小于当前 TD 的大小。可以进入 req_done 处理
		req_done(udc_ep_ptr, udc_req_ptr, 0)
		// 会将 usb 数据送入到 complete 进行处理
	}
}
```

对于批量和中断 EPs，TD 由普通 TRB 和可选的链路 TRB 组成。准备好 TD)后，软件通知设备控制器传输更多的 TDs .

在 TRBs 传输完成 （设置了 IOC bit）、出现 short packet 或者 出现错误时，设备控制器生成 完成事件。

对于批量传输 （Bulk） 或者 中断传输 （Interrupt transfers）。提供以下完成代码：

> 见 **8.3.7Handling Bulk and Interrupt Transfers**

- Completion Code （comp_code）: 此字段表示所指向的 TRB 的完成状态。对于在进行到下一个 TD 时设置了 IOC 位的 TRB 生成的传输事件，应忽略该字段。

```c
enum TRB_CMPL_CODES_E {
	CMPL_CODE_INVALID       = 0,
	CMPL_CODE_SUCCESS,
	CMPL_CODE_DATA_BUFFER_ERR,
	CMPL_CODE_BABBLE_DETECTED_ERR,
	CMPL_CODE_USB_TRANS_ERR,
	CMPL_CODE_TRB_ERR,  /*5*/
	CMPL_CODE_TRB_STALL,
	CMPL_CODE_INVALID_STREAM_TYPE_ERR = 10,
	CMPL_CODE_SHORT_PKT = 13,
	CMPL_CODE_RING_UNDERRUN,
	CMPL_CODE_RING_OVERRUN, /*15*/
	CMPL_CODE_EVENT_RING_FULL_ERR = 21,
	CMPL_CODE_STOPPED = 26,
	CMPL_CODE_STOPPED_LENGTH_INVALID = 27,
	CMPL_CODE_ISOCH_BUFFER_OVERRUN = 31,
	/*192-224 vendor defined error*/
	CMPL_CODE_PROTOCOL_STALL = 192,
	CMPL_CODE_SETUP_TAG_MISMATCH = 193,
	CMPL_CODE_HALTED = 194,
	CMPL_CODE_HALTED_LENGTH_INVALID = 195,
	CMPL_CODE_DISABLED = 196,
	CMPL_CODE_DISABLED_LENGTH_INVALID = 197,
};
```

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/image.1g7hwqd3alnk.webp)

#### is_request_dequeued

```c
bool is_request_dequeued(struct crg_gadget_dev *crg_udc,
		struct crg_udc_ep *udc_ep, struct event_trb_s *event)
{
	// 获取请求环的地址
	trb_pt = tran_trb_dma_to_virt(udc_ep, trb_addr);
}
```

### crg_handle_setup_pkt

```c
void crg_handle_setup_pkt(struct crg_gadget_dev *crg_udc,
		struct usb_ctrlrequest *setup_pkt, u8 setup_tag)
{
	/* EP0 come backs to running when new setup packet comes*/
	crg_udc->udc_ep[0].ep_state = EP_STATE_RUNNING;

//标准请求，用于 SETUP 数据包的 bRequest 字段
//这些由 bRequestType 字段限定，因此例如 TYPE_CLASS 或 TYPE_VENDOR 特定功能标志可以通过 GET_STATUS 请求检索。
	switch (setup_pkt->bRequest) {
	case USB_REQ_GET_STATUS:
		// Get status request RequestType
		getstatusrequest(crg_udc, setup_pkt->bRequestType
					wValue, wIndex, wLength);
			//crg_udc_build_td
	case USB_REQ_SET_ADDRESS:
		setaddressrequest(crg_udc, wValue, wIndex, wLength);
	case USB_REQ_SET_SEL:
		setselrequest(crg_udc, wValue, wIndex, wLength, wData);
	case USB_REQ_SET_ISOCH_DELAY:
		set_isoch_delay(crg_udc, wValue, wIndex, wLength);
	}
}
```

## crg_udc_build_td

- 先判断是否需要完成上一次未完成的传输

```c
if (udc_req_ptr->trbs_needed)

// 接着根据 trb 的类型来进行入队
if (usb_endpoint_xfer_control(udc_ep_ptr->desc))  // 控制传输类型
if (usb_endpoint_xfer_isoc(udc_ep_ptr->desc))     // 等时传输类型
if (usb_endpoint_xfer_bulk(udc_ep_ptr->desc))     // 批量传输类型
```

---------

## UDC core 源码分析

drivers/usb/gadget/udc/core.c

```c
udc_class = class_create(THIS_MODULE, "udc");
// udc_class 这个是一个全局变量
// 在 usb_add_gadget_udc_release 函数被使用

class_create --> __class_create --> __class_register
```

通过调用 class_create 函数，内核会在 /sys/class 目录下创建一个名为"udc"的子目录，该目录用于表示与这个设备类相关的设备。这个设备类可以被 USB gadget 驱动程序使用，以便为 USB 主机提供虚拟设备的支持。

```sh
# 在配置 UDC 时
echo "fdd00000.crgudc2"> /sys/kernel/config/usb_gadget/amlogic/UDC 

 ls sys/class/udc/
fe320000.crgudc2
```

USB gadget 驱动程序是一种爱 linux 内核中实现 USB 设备功能的的技术，它允许将 linux 系统转换为一个虚拟的 USB 设备，以便与 USB 主机进行通信。

USB gadget 驱动程序可以将 UDC（USB Device Controller）硬件接口映射到"/sys/class/udc"目录下的设备节点上。通过这个设备节点，USB gadget 驱动程序可以向 USB 主机发送各种控制信息并接收来自 USB 主机的数据。

### usb_add_gadget_udc_release

```c
ret = dev_set_name(&udc->dev, "%s", kobject_name(&parent->kobj));

printk("parent->kobj.name = %s\n",  parent->kobj.name); // fe320000.crgudc2
printk("dev_name(&udc->dev) = %s\n",  dev_name(&udc->dev)); // fe320000.crgudc2
```

-------------

# phy-aml-crg-drd-otg

```c
static int amlogic_crg_otg_probe(struct platform_device *pdev)
{
	INIT_DELAYED_WORK(&phy->work, amlogic_crg_otg_work);

	retval = request_irq(irq, amlogic_crgotg_detect_irq,
			IRQF_SHARED, "amlogic_botg_detect", phy);
		// 这里调用 schedule_delayed_work(&phy->work, msecs_to_jiffies(10)); 
	
	if (otg == 0) {
	} else {
		INIT_DELAYED_WORK(&phy->set_mode_work, amlogic_crg_otg_set_m_work);
		schedule_delayed_work(&phy->set_mode_work, msecs_to_jiffies(500));
	}
}
// 推迟执行
static void amlogic_crg_otg_set_m_work(struct work_struct *work)
{
	set_mode(reg_addr, DEVICE_MODE, phy3_addr);
	amlogic_m31_set_vbus_power(phy, 0)
	crg_gadget_init();
}
```

