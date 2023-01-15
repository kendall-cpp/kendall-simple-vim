
<!-- TOC -->

- [ALSA 声卡驱动](#alsa-声卡驱动)
	- [PCM](#pcm)
	- [ASOC 简介](#asoc-简介)
		- [Linux ALSA音频系统架构](#linux-alsa音频系统架构)
		- [ASOC硬件架构](#asoc硬件架构)
- [注册 aml\_tdm\_driver](#注册-aml_tdm_driver)
	- [module\_platform\_driver](#module_platform_driver)
	- [通过 module\_platform\_driver 注册 aml\_tdm\_driver](#通过-module_platform_driver-注册-aml_tdm_driver)
		- [platform 驱动之 probe 函数](#platform-驱动之-probe-函数)
		- [aml\_tdm\_driver 的 probe 函数](#aml_tdm_driver-的-probe-函数)
	- [aml\_tdm\_platform\_probe 函数分析](#aml_tdm_platform_probe-函数分析)
		- [match data 匹配数据](#match-data-匹配数据)
		- [获取设备控制器和控制节点](#获取设备控制器和控制节点)

<!-- /TOC -->

-----------------


# ALSA 声卡驱动


ALSA是 Advanced Linux Sound Architecture 的缩写，目前已经成为了linux的主流音频体系结构，想了解更多的关于ALSA的这一开源项目的信息和知识，请查看以下网址：http://www.alsa-project.org/。

在内核设备驱动层，ALSA提供了 alsa-driver，同时在应用层，ALSA 为我们提供了alsa-lib，应用程序只要调用 alsa-lib 提供的 API，就可以完成对底层音频硬件的控制。

![](https://img-blog.csdnimg.cn/20200309171315252.gif?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0JpbGxfeGlhbw==,size_16,color_FFFFFF,t_70)


用户空间的 alsa-lib 对应用程序提供统一的API接口，这样可以隐藏了驱动层的实现细节，简化了应用程序的实现难度。内核空间中，alsa-soc (ASOC) 其实是对 alsa-driver 的进一步封装，他针对嵌入式设备提供了一些列增强的功能

- `kernel/sound/core` 该目录包含了ALSA驱动的中间层，它是整个ALSA驱动的核心部分。

- `kernel/sound/soc` 针对system-on-chip体系的中间层代码

## PCM

PCm（Pulse-code modulation）也就是 脉冲编码调制 。 在我们相识生活中，人耳朵能听到的声音是模拟信号，PCM 就是需要把这些模拟信号转换成数字信号的一种技术。

- PCM：将声音 模拟信号（人耳听到） ---> 数字信号

- 原理： 利用一个固定的频率，对模拟信号进行采样，采样后的信号在波形上看就像一串连续但幅值的脉冲，把这些脉冲的幅值按照一定的精度进行量化，这些量化后的数值被连续地输出、传输、处理或者记录到存储介质中，所有这些组成了数字音频的过程。

- PCM信号的指标：
  - 采样频率： 通常是 44100HZ
  - 量化精度： 通常是 16bit

在播放音乐时，从存储介质中读音频数据库，经过解码后，送到音频驱动中的就是 PCM 数据。

录音时，音频驱动不停地把采样所得到的 PCM 数据送回给应用程序。

所以音频驱动的两大任务：

- playback 如何把用户空间的应用程序发过来的 PCM 数据，转化为人耳可以辨别的模拟音频
- capture 把 音频驱动 采样得到的模拟信号，经过采样、量化，转换为 PCM 信号送回给用户空间的应用程序

## ASOC 简介

> **为什么会有 ASOC？**

ASOC (ALSA System on Chip) 建立在标准ALSA驱动层上，为了更好地支持嵌入式处理器和移动设备中的音频Codec的一套软件体系。在 ASOC 之前的 SOC 中的音频存在一些局限。

- Codec 驱动与 SoC CPU 的底层耦合过于紧密，这种不理想会导致代码的重复，例如，仅是wm8731的驱动，当时Linux中有分别针对4个平台的驱动代码。
  
- 音频事件没有标准的方法来通知用户，例如耳机、麦克风的插拔和检测，这些事件在移动设备中是非常普通的，而且通常都需要特定于机器的代码进行重新对音频路劲进行配置。

- 当进行播放或录音时，驱动会让整个 codec 处于上电状态，这对于 PC 没问题，但对于移动设备来说，这意味着浪费大量的电量。同时也不支持通过改变过取样频率和偏置电流来达到省电的目的。

- ASoC正是为了解决上述种种问题而提出的，目前已经被整合至内核的代码树中：`sound/soc`。ASoC 不能单独存在，他只是建立在标准 ALSA 驱动上的一个它必须和标准的 ALSA 驱动框架相结合才能工作。

### Linux ALSA音频系统架构

- **Alsa application**: aplay, arecord, amixer, 是 alsa alsa-tools 中提供的上层调试工具，用户可以直接将其移植到自己所需要的平台，这些应用可以用来实现 playback, capture, controls 等。
- **alsa library API**: alsa 用户库接口，常见有 alsa-lib. ( alsa-tools 中的应用程序基于 alsa-lib 提供的 api 来实现)
- **ALSA core**: alsa　核心层，向上提供逻辑设备(`pcm/ctl/midi/timer/..`)系统调用，向下驱动硬件设备(`Machine/i2s/dma/codec`)
- **ASsoc core**:asoc是建立在标准alsa core基础上，为了更好支持嵌入式系统和应用于移动设备的音频codec的一套软件体系。
- **hardware driver**: 音频硬件设备驱动，由三大部分组成，分别是 machine, platform, codec .

### ASOC硬件架构

**ASoC 把音频系统同样分为3大部分：Machine，Platform 和 Codec**

在 ASoC 驱动框架中 cpu 部分称作 platform，声卡部分被称作 codec，两者通过 machine 进行匹配连接；machine 可以理解为对开发板的抽象，开发板可能包括多个声卡.

Platform  一般是指某一个SoC平台，比如 MT6582, MT6595, MT6752 等等，与音频相关的通常包含该SoC中的Clock、FAE、I2S、DMA等等,该模块负责DMA的控制和I2S的控制, 由CPU厂商负责编写此部分代码。

- 录音数据通路：麦克风---->声卡–(I2S)->DMA---->内存；
- 播放数据通路：内存---->DMA–(I2S)->声卡---->扬声器；

- platform：platform+cpu_dai     

Codec  字面上的意思就是编解码器， Codec 里面包含了 I2S 接口、 DAC 、 ADC 、 Mixer 、 PA （功放），通常包含多种输入（ Mic 、 Line-in 、 I2S 、 PCM ）和多个输出（耳机、喇叭、听筒， Line-out ）， Codec 和 Platform一样，是可重用的部件。该模块负责AFIx的控制和DAC部分的控制(也可以说是芯片自身的功能的控制), 由Codec厂商负责编写此部分代码

- Codec: codec+codec_dai
 
Machine 是指某一款机器，可以是某款设备，某款开发板，又或者是某款智能手机，由此可以看出Machine几乎是不可重用的，每个Machine上的硬件实现可能都不一样，CPU不一样，Codec不一样，音频的输入、输出设备也不一样，Machine为CPU、Codec、输入输出设备提供了一个载体 ，用于描述一块电路板, 它指明此块电路板上用的是哪个Platform和哪个Codec, 由电路板商负责编写此部分代码。 绑定 platform driver 和 codec driver


![](https://img-blog.csdnimg.cn/20200309172704582.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0JpbGxfeGlhbw==,size_16,color_FFFFFF,t_70)

---

# 注册 aml_tdm_driver

## module_platform_driver

module_platform_driver() 用于在模块 初始化/退出 时, 不需要执行任何特殊操作的驱动程序。 遮掩每个模块只能使用一次这个宏，调用它来代替 module_init() 和 module_exit()。

也就是说注册一个驱动，注销调用 module_platform_driver(driver) 这个函数即可，这个函数会注册和注销创建来的 driver。

## 通过 module_platform_driver 注册 aml_tdm_driver

```c
#define DRV_NAME "snd_tdm"

struct platform_driver aml_tdm_driver = {
	.driver  = {
		.name           = DRV_NAME,  // 设备驱动的名字 snd_tdm
		.of_match_table = aml_tdm_device_id,  
		//aml_tdm_device_id 是驱动文件的匹配列表， 也就是设置这个 platform_driver 所使用的 OF 匹配表
	},
	.probe   = aml_tdm_platform_probe,
	.suspend = aml_tdm_platform_suspend,
	.resume  = aml_tdm_platform_resume,
};
```

`platform_driver.suspend/resume` 的是电源管理相关函数。korlan 中暂时不需要使用这两个函数。

### platform 驱动之 probe 函数

probe 函数在设备驱动注册最后收尾工作，当设备的 device 和其对应的 driver 在总线上完成配对之后，系统就调用 platform 设备的 probe 函数完成驱动注册最后工作。资源、 中断调用函数以及其他相关工作。下面是 probe 被调用的一些程序流程。

### aml_tdm_driver 的 probe 函数

```c
static int aml_tdm_platform_probe(struct platform_device *pdev)   // pdev 表示这个 platform_device

//有几个比较重要的结构体
struct aml_audio_controller *actrl = NULL;   // 控制器的数据
struct aml_tdm *p_tdm = NULL;
struct tdm_chipinfo *p_chipinfo;  // 保存设备节点的数据
```

## aml_tdm_platform_probe 函数分析

### match data 匹配数据

```c
p_chipinfo = (struct tdm_chipinfo *) of_device_get_match_data(dev);

// dev：设备节点
// 返回值：没有 data 则返回NULL，成功则返回 data
```

of_device_get_match_data 函数主要是通过调用 of_match_device 来实现，通过设备节点，获取设备节点里面的 data 属性。

为了使同一个 driver 中支持多个 soc，可以将 struct pinctrl_desc 变量的指针保存在每个 soc 的 match table 中，并在 probe 中借助 of_device_get_match_data 将其获取出来。

- 接着把从 dev 设备节点中获取到的数据存到 p_tdm 中

```c
p_tdm->chipinfo = p_chipinfo;
p_tdm->id = p_chipinfo->id;
p_tdm->lane_cnt = p_chipinfo->lane_cnt
// p_chipinfo->lane_cnt 表示最大 lane 通道数
```

### 获取设备控制器和控制节点

```c
/* get audio controller */
node_prt = of_get_parent(node);

pdev_parent = of_find_device_by_node(node_prt);
actrl = (struct aml_audio_controller *) platform_get_drvdata(pdev_parent);
```

platform_get_drvdata(_dev) 是为通过传入 struct platform_device 结构体类型的指针，得到设备传给驱动的数据。与 platform_set_drvdata 函数相对应。

> [参考：平台总线之platform_get_drvdata(_dev)宏分析](https://blog.csdn.net/qq_16777851/article/details/80834926)

这样做主要是为了驱动数据和驱动操作分离。这样可以尽可能的让一个驱动程序，被多个驱动设备所使用。



> vim korlan-sdk/kernel/sound/soc/amlogic/auge/tdm.c +1629