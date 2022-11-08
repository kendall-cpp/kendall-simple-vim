```c
/**
 	struct usb_driver -确认到usbcore的接口驱动
 name:USB驱动之间，驱动的名字必须是独特的，并且和模块的名称通常一样
 probe:为了查看驱动是否能够管理设备上的一个独特的接口，如果能，probe返回0，并且
 使用usb_set_intfdata()整合驱动特性的数据与接口，同样肯呢过使用use usb_set_interface()
 去确定合适的altsetting。如果不能管理接口，返回-ENODEV。若IO错误出现，返回一个
 负值。
 disconnect:如果接口不能被访问就调用这个函数，常常因为设备没有连接或者驱动
 模块没有加载。
 unlocked_ioctl:若驱动想访问用户空间澹(通过usbfs文件系统)就会调用这个函数。
 这个函数能使设备暴露信息到用户空间而不用去管其他的
 suspend:系统禁用设备时会调用这个函数
 resume:系统重新调用设备时会调用这个函数
 reset_resume:当挂起的设备被复位而不是重新调用的时候调用这个函数
 pre_reset:当设备复位要复位时，被usb_reset_device()调用，这个例程直到驱动没有
 对设备没有活动的URBS才能返回，并且没有URBS被递交
 post_reset:设备复位后，被usb_reset_device()函数调用
 id_table:USB驱动使用ID table支持热插拔。输出参数到MODULE_DEVICE_TABLE().
 这是必须配置的，除非你的驱动probe函数永远不会调用
 dynids:用来保持设备id的链表
 drvwrap:驱动模型核心结构体的封装。
 no_dynamic_id:如果配置成1，USB核心将不会允许动态id被加入到驱动(通过阻止系统
 文件的创建)
 supports_autosuspend:如果配置成0，USB核心不会允许自动挂起驱动
 soft_unbind:如果配置成1，USB核心在调用驱动断开连接函数前不会杀手URBS和
 禁止使能端点。
 disable_hub_initiated_lpm:如果配置成0，当理想时间超时，USB核心不会允许HUBS
 初始化低功耗连接状态转换。
 USB接口驱动必须提供name，probe()。disconnect().和id_table。其他的可以
 自行配置
 id_table是在热插拔中使用的，它持有一组描述符，并且具体的数据也许会和每个
 条目都有关系。这个table在用户或者内核模式下都支持热插拔
 probe() disconnect()函数方法应该避免滥用，大部分连接设备的工作应该在设备
 唤醒的时候才调用，在设备关闭的时候不调用。
 */
struct usb_driver {
	const char *name;
 
	int (*probe) (struct usb_interface *intf,
		      const struct usb_device_id *id);
 
	void (*disconnect) (struct usb_interface *intf);
 
	int (*unlocked_ioctl) (struct usb_interface *intf, unsigned int code,
			void *buf);
 
	int (*suspend) (struct usb_interface *intf, pm_message_t message);
	int (*resume) (struct usb_interface *intf);
	int (*reset_resume)(struct usb_interface *intf);
 
	int (*pre_reset)(struct usb_interface *intf);
	int (*post_reset)(struct usb_interface *intf);
 
	const struct usb_device_id *id_table;
 
	struct usb_dynids dynids;
	struct usbdrv_wrap drvwrap;
	unsigned int no_dynamic_id:1;
	unsigned int supports_autosuspend:1;
	unsigned int disable_hub_initiated_lpm:1;
	unsigned int soft_unbind:1;
};
```