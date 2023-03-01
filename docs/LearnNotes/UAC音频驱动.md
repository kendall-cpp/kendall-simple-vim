2

## UAC2

UVC（USB Audio Class）定义了使用USB协议播放或采集音频数据的设备应当遵循的规范。目前，UAC协议有UAC1.0和UAC2.0。UAC2.0协议相比UAC1.0协议，提供了更多的功能，支持更高的带宽，拥有更低的延迟。Linux内核中包含了UAC1.0和UAC2.0驱动，分别在f_uac1.c和f_uac2.c文件中实现。下面将以UAC2驱动为例，具体分析USB设备驱动的初始化、描述符配置、数据传输过程等。 


alloc_inst 被设置为 afunc_alloc_inst，alloc_func 被设置为 afunc_alloc，这两个函数在 Gadget Function API 层被回调。宏 DECLARE_USB_FUNCTION_INIT 将定义一个 usb_function_driver 数据结构，使用 usb_function_register 函数注册到 function API 层。

```sh
drivers/usb/gadget/function/f_uac2.c

DECLARE_USB_FUNCTION_INIT(uac2, afunc_alloc_inst, afunc_alloc); 
```

先来看看 f_uac2 结构体, 由 afunc_alloc 分配，包含具体音频设备和 USB 配置信息。

```c
struct f_uac2 {
	struct g_audio g_audio;
	u8 ac_intf, as_in_intf, as_out_intf;
// - ac_intf - audio control interface，接口描述符编号为0
// - as_in_intf - audio streaming in interface，接口描述符编号为2
// - as_out_intf - audio streaming out interface，接口描述符编号为1

	u8 ac_alt, as_in_alt, as_out_alt;	/* needed for get_alt() */
};


//g_audio 表示音频设备，包含了音频运行时参数、声卡、PCM设备等信息
struct g_audio {
	struct usb_function func;  // 描述了USB设备功能的回调函数
	struct usb_gadget *gadget;

	struct usb_ep *in_ep;   //输入端点
	struct usb_ep *out_ep;  // 输出端点

	/* Max packet size for all in_ep possible speeds */
	unsigned int in_ep_maxpsize;  // 输入端点数据包最大长度
	/* Max packet size for all out_ep possible speeds */
	unsigned int out_ep_maxpsize;  // 输出端点数据包最大长度

	/* The ALSA Sound Card it represents on the USB-Client side */
	struct snd_uac_chip *uac;

	struct uac_params params;  // 音频参数
};
```