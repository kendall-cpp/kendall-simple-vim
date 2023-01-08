- [ALSA 声卡驱动](#alsa-声卡驱动)
	- [ASOC 简介](#asoc-简介)

-----------------


# ALSA 声卡驱动


ALSA是 Advanced Linux Sound Architecture 的缩写，目前已经成为了linux的主流音频体系结构，想了解更多的关于ALSA的这一开源项目的信息和知识，请查看以下网址：http://www.alsa-project.org/。

在内核设备驱动层，ALSA提供了alsa-driver，同时在应用层，ALSA为我们提供了alsa-lib，应用程序只要调用alsa-lib提供的API，即可以完成对底层音频硬件的控制。

![](https://img-blog.csdnimg.cn/20200309171315252.gif?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0JpbGxfeGlhbw==,size_16,color_FFFFFF,t_70)


用户空间的alsa-lib对应用程序提供统一的API接口，这样可以隐藏了驱动层的实现细节，简化了应用程序的实现难度。内核空间中，alsa-soc (ASOC) 其实是对 alsa-driver 的进一步封装，他针对嵌入式设备提供了一些列增强的功能

kernel/sound/core该目录包含了ALSA驱动的中间层，它是整个ALSA驱动的核心部分。

kernel/sound/soc 针对system-on-chip体系的中间层代码

## ASOC 简介

ASoC把音频系统同样分为3大部分：Machine，Platform 和 Codec

在 ASoC 驱动框架中 cpu 部分称作 platform，声卡部分被称作 codec，两者通过 machine 进行匹配连接；machine 可以理解为对开发板的抽象，开发板可能包括多个声卡.

Platform  一般是指某一个SoC平台，比如 MT6582, MT6595, MT6752 等等，与音频相关的通常包含该SoC中的Clock、FAE、I2S、DMA等等,该模块负责DMA的控制和I2S的控制, 由CPU厂商负责编写此部分代码。

- 录音数据通路：麦克风---->声卡–(I2S)->DMA---->内存；
- 播放数据通路：内存---->DMA–(I2S)->声卡---->扬声器；

- platform：platform+cpu_dai     

Codec  字面上的意思就是编解码器， Codec 里面包含了 I2S 接口、 DAC 、 ADC 、 Mixer 、 PA （功放），通常包含多种输入（ Mic 、 Line-in 、 I2S 、 PCM ）和多个输出（耳机、喇叭、听筒， Line-out ）， Codec 和 Platform一样，是可重用的部件。该模块负责AFIx的控制和DAC部分的控制(也可以说是芯片自身的功能的控制), 由Codec厂商负责编写此部分代码

- Codec: codec+codec_dai
 
Machine 是指某一款机器，可以是某款设备，某款开发板，又或者是某款智能手机，由此可以看出Machine几乎是不可重用的，每个Machine上的硬件实现可能都不一样，CPU不一样，Codec不一样，音频的输入、输出设备也不一样，Machine为CPU、Codec、输入输出设备提供了一个载体 ，用于描述一块电路板, 它指明此块电路板上用的是哪个Platform和哪个Codec, 由电路板商负责编写此部分代码。 绑定 platform driver 和 codec driver


![](https://img-blog.csdnimg.cn/20200309172704582.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0JpbGxfeGlhbw==,size_16,color_FFFFFF,t_70)



