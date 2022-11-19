# GPIO 子系统的作用

芯片内部有很多引脚，这些引脚可以接到 GPIO 模块，也可以接到 I2C 模块，通过 Pinctrl 子系统来选择引脚的功能（mux function），配置引脚。当一个引脚被复用为 GPIO 功能时，我们可以去设置它的方向（输入或者输出），设置/读取 它的值。GPIO 可能是芯片自带的，也可能是通过I2C、SPI接口扩展。

![](https://img-blog.csdnimg.cn/1aa6ca3fb83a40e1a59aaa51aa5223f9.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5Lmg5oOv5bCx5aW9eno=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 通用功能

- 可以设为输出，让它输出高低电平
- 可以设为输入，读取引脚当前电平
- 可以用来触发中断

对于芯片自带的GPIO，它的访问速度很快，可以在获得spinlocks的情况下操作它。但是，对于通用I2C、SPI等接口扩展的GPIO，访问它们时可能导致休眠，所以这些“GPIO Expander”就不能在获得spinlocks的情况下使用。

linux 内核中提供了 GPIO 子系统，我们在驱动代码中使用 GPIO 子系统的 API 函数去控制 GPIO


> 深入理解 gpio: http://www.wowotech.net/sort/gpio_subsystem

# pinctrl 子系统概念

一个设备（URAT)有两个状态，默认和休眠状态，默认状态时将对应引脚设置为 这个 URAT 功能，休眠状态时将引脚设置为普通的 GPIO 功能。

```c
device {
	pinctrl-names = "default", "sleep";   //1.设置设备的两种状态
	pinctrl-0 = <&state_0_node_a>; //设置0状态的名字是 default，对应的引脚在 pinctrl-0里面定义
	//这个节点描述在这个状态下要怎么做，这些节点位于 pinctrl 节点里面
	pinctrl-1 = <&state_1_node_a>; //第1状态的名字是sleep，对应的引脚在pinctrl-1里定义
};

picontroller {
	state_0_node_a {
		function = "urat0";
		groups = "u0rxtx", "u0rtscts";
	}
	state_1_node_a {
		function = "gpio";
		groups = "u0rxtx", "u0rtscts";
	}
};
```

- 当这个设备属于 default 状态时，会使用 state_0_node_a 这个节点来配置引脚。也就是会把这一组引脚配置成 urat0 功能
- 当这个设备属于 sleep 状态时，会使用 state_1_node_a 这个节点来配置引脚，也就是会把这一组引脚配置成 gpio 功能

所以 state_0_node_a 和 state_1_node_a 的作用就是复用引脚的功能，在内核中这类的引脚成为 pin multiplexing node .


```c
device {
	pinctrl-names = "default", "sleep";   //1.设置设备的两种状态
	pinctrl-0 = <&state_0_node_a>; 
	//这个节点描述在这个状态下要怎么做，这些节点位于 pinctrl 节点里面
	pinctrl-1 = <&state_1_node_a>; 
};

picontroller {
	state_0_node_a {
		function = "urat0";
		groups = "u0rxtx", "u0rtscts";
	}
	state_1_node_a {
		groups = "u0rxtx", "u0rtscts";
		output-high;
	}
};
```

- 当这个设备属于 default 状态时，会使用 state_0_node_a 这个节点来配置引脚。也就是会把这一组引脚配置成 urat0 功能
- 当这个设备属于 sleep 状态时，会使用 state_1_node_a 这个节点来配置引脚，也就是会把这一组引脚配置成 输出高电平

这类节点成为 pin configuration node 。


https://www.cnblogs.com/zhuangquan/p/12750736.html





