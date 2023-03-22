3

# UAC

## UAC2

UVC（USB Audio Class）定义了使用USB协议播放或采集音频数据的设备应当遵循的规范。目前，UAC协议有UAC1.0和UAC2.0。UAC2.0协议相比UAC1.0协议，提供了更多的功能，支持更高的带宽，拥有更低的延迟。Linux内核中包含了UAC1.0和UAC2.0驱动，分别在f_uac1.c和f_uac2.c文件中实现。这里主要以UAC2驱动为例，具体分析USB设备驱动的初始化、描述符配置、数据传输过程等。 


alloc_inst 被设置为 afunc_alloc_inst，alloc_func 被设置为 afunc_alloc，这两个函数在 Gadget Function API 层被回调。宏 DECLARE_USB_FUNCTION_INIT 将定义一个 usb_function_driver 数据结构，使用 usb_function_register 函数注册到 function API 层。关于 Function 层，后面文章会总结。

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

### afunc_alloc_inst

- afunc_alloc_inst 里面主要是分配一个 usb_function_instance （音频数据） 实例结构体，并赋值一些默认参数。**这里注意两个参数 p_chmask 和 c_chmask** ，如果你从事的是 linux 内核相关的工作，声音播放一段时间后出现 underrun 问题（kernel log), 或者 overrun (应用 log) 问题，可以检查一下这两个参数是否设置正确。

- 另外还有这个函数：afunc_free_inst ，这个函数就不用说了吧，看看函数名字再对比下 afunc_alloc_inst 这个函数名字，很明显是一个分配一个释放嘛，走进函数内部一看，发现就只有一行核心代码：`opts = container_of(f, struct f_uac2_opts, func_inst);`  。没错，我就是要引出 container_of 这个函数，这个函数啥功能呢？我也不懂~~，后续学习补上【链接】


```c
static struct usb_function_instance *afunc_alloc_inst(void)                                                                                                                                                      
{
		struct f_uac2_opts *opts;  //ops保存音频属性参数信息

		opts = kzalloc(sizeof(*opts), GFP_KERNEL);
		if (!opts)
				return ERR_PTR(-ENOMEM);

		mutex_init(&opts->lock);
		
		opts->func_inst.free_func_inst = afunc_free_inst;

		//这里是用来给用户空间操作的节点，简单的说就是这个函数的功能是让用户空间可以修改音频的参数
		config_group_init_type_name(&opts->func_inst.group, "",
									&f_uac2_func_type);

		//默认参数在 u_uac2.h 中设置
		opts->p_chmask = UAC2_DEF_PCHMASK;  //0x3  默认录音是双声道
		opts->p_srate = UAC2_DEF_PSRATE;    //48000
		opts->p_ssize = UAC2_DEF_PSSIZE;	//2
		opts->c_chmask = UAC2_DEF_CCHMASK;	//0x3  默认播放是双声道
		opts->c_srate = UAC2_DEF_CSRATE;	//64000  默认播放采样率是 64000， 一般都会改成 48000
		opts->c_ssize = UAC2_DEF_CSSIZE;	//2  一般都会改成 4
		opts->req_number = UAC2_DEF_REQ_NUM;  //2
		return &opts->func_inst;
}
```

- f_uac2_opts 这个数据结构定义了音频数据的一些属性参数

```c
struct f_uac2_opts {
	struct usb_function_instance	func_inst;  // 功能回调函数
	int				p_chmask;  // 录音通道掩码
	int				p_srate;   // 录音采样率
	int				p_ssize;   // 录音一帧数据占多少字节
	int				c_chmask;  // 播放通道掩码
	int				c_srate;   // 播放采样率
	int				c_ssize;   // 播放一帧数据占多少字节
	int				req_number;  // usb_request的数量
	bool			bound;
	struct mutex	lock;
	int				refcnt;  // 引用计数
};	
```

### afunc_alloc

主要是设置一些操作函数，初始化接口端点描述符，最后初始化一个虚拟ALSA声卡

```c
static struct usb_function *afunc_alloc(struct usb_function_instance *fi)
{
	struct f_uac2	*uac2;
	struct f_uac2_opts *opts;

	uac2 = kzalloc(sizeof(*uac2), GFP_KERNEL);
	if (uac2 == NULL)
		return ERR_PTR(-ENOMEM);

	opts = container_of(fi, struct f_uac2_opts, func_inst);
	mutex_lock(&opts->lock);
	++opts->refcnt;
	mutex_unlock(&opts->lock);

	uac2->g_audio.func.name = "uac2_func";  // //这里是function的名字
	uac2->g_audio.func.bind = afunc_bind;	// //用来绑定设备和 function 的函数
	uac2->g_audio.func.unbind = afunc_unbind;
	uac2->g_audio.func.set_alt = afunc_set_alt;  // composite_setup 这里调用
	uac2->g_audio.func.get_alt = afunc_get_alt;
	uac2->g_audio.func.disable = afunc_disable;
	uac2->g_audio.func.setup = afunc_setup;
	uac2->g_audio.func.free_func = afunc_free;

	//control_selector_init(uac2);  可以通过这个函数添加扩展的控制器

	return &uac2->g_audio.func;
}
```






https://blog.csdn.net/u011037593/article/details/121458492

https://blog.csdn.net/u011037593/article/details/123698241?spm=1001.2014.3001.5501


# 待学习

- container_of ： https://blog.csdn.net/wzc18743083828/article/details/118730678