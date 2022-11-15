# GPIO 子系统的作用

芯片内部有很多引脚，这些引脚可以接到 GPIO 模块，也可以接到 I2C 模块，通过 Pinctrl 子系统来选择引脚的功能（mux function），配置引脚。当一个引脚被复用为 GPIO 功能时，我们可以去设置它的方向（输入或者输出），设置/读取 它的值。GPIO 可能是芯片自带的，也可能是通过I2C、SPI接口扩展。

![](https://img-blog.csdnimg.cn/1aa6ca3fb83a40e1a59aaa51aa5223f9.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5Lmg5oOv5bCx5aW9eno=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 通用功能

- 可以设为输出，让它输出高低电平
- 可以设为输入，读取引脚当前电平
- 可以用来触发中断

对于芯片自带的GPIO，它的访问速度很快，可以在获得spinlocks的情况下操作它。但是，对于通用I2C、SPI等接口扩展的GPIO，访问它们时可能导致休眠，所以这些“GPIO Expander”就不能在获得spinlocks的情况下使用。

linux 内核中提供了 GPIO 子系统，我们在驱动代码中使用 GPIO 子系统的 API 函数去控制 GPIO

> 参考：https://www.cnblogs.com/liangliangge/category/1485102.html

## GPIO 常用 API 总结

```c
static inline bool gpio_is_valid(int number)
{
    return number >= 0 && number < ARCH_NR_GPIOS;
}
```

函数 gpio_is_valid() 用来判断获取到的 gpio 号是否是有效的，只有有效的 gpio 号，才能向内核中进行申请使用，因此，当我们从设备树的设备节点获取到 gpio 号，可以使用该函数进行判断是否有效。

```c
extern int gpio_request(unsigned gpio, const char *label);
extern void gpio_free(unsigned gpio);
```

上面这两个函数用来向系统中申请 GPIO 和释放已经申请的 GPIO，在函数 gpio_request() 中传入的形参中，gpio 为 IO 号，label 为向系统中申请 GPIO使 用的标签，类似于 GPIO 的名称。

struct gpio 用来描述一个需要配置的GPIO

```c
struct gpio {
	unsigned    gpio;
	unsigned long   flags;
	const char  *label;
};
```
https://www.bilibili.com/video/BV1w4411B7a4?p=114&vd_source=8578a3631d2dfb10ea828e367b923283
 
https://www.51cto.com/article/689477.html

http://www.wowotech.net/sort/gpio_subsystem

https://www.freesion.com/article/89301077969/

https://zhuanlan.zhihu.com/p/400309588

https://www.cnblogs.com/zhuangquan/p/12750736.html

https://www.cnblogs.com/liangliangge/p/11891789.html