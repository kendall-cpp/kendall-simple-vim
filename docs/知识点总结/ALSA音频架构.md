- [ALSA音频工具arecord、aplay、amixer使用](#alsa音频工具arecordaplayamixer使用)
  - [arecord与aplay](#arecord与aplay)
  - [amixer](#amixer)
  - [一些概念](#一些概念)
    - [音频接口：TDM，PDM，I2S，PCM](#音频接口tdmpdmi2spcm)
    - [cpu_dai](#cpu_dai)
    - [Linux 内存映射函数 mmap 函数](#linux-内存映射函数-mmap-函数)

----

## ALSA音频工具arecord、aplay、amixer使用

### arecord与aplay

```sh
arecord  -l  # 查询 linux 系统下设备声卡信息

arecord -D hw:0,0 -r 16000 -c 1 -f S16_LE test.wav  # 录制音频

Recording WAVE 'test.wav' : Signed 16 bit Little Endian, Rate 16000 Hz, Mono
^CAborted by signal Interrupt...  # 这里使用Ctrl+c 结束了录制

aplay -Dhw:0,0 /data/the-stars-48k-60s.wav   # 播放音频
```


### amixer

- amixer controls 用于查看音频系统提供的操作接口
- amixer contents 用于查看接口配置参数
- amixer cget + 接口函数
- amixer cset + 接口函数 + 设置值

```sh
amixer cget numid=2       # 查看音量
amixer cset numid=2 150   # 修改音量
# 或者
amixer cset numid=2,iface=MIXER,name='tas5805 Digital Volume' 150
```


> **ALSA 驱动 asoc 框架主要包括 codec driver、 platform driver、 machine driver**



### 一些概念

#### 音频接口：TDM，PDM，I2S，PCM 

> https://blog.51cto.com/u_12810168/2450275

- TMD 有些IC支持使用一个公共时钟的多路I2S数据输入或输出，但这样的方法显然会增加数据传输所需要的管脚数量。当同一个数据线上传输两个以上通道的数据时，就要使用TDM格式。TDM数据流可以承载多达16通道的数据，并有一个类似于 I2S 的 数据/时钟 结构

- 传输单声道数据：PCM
  - 比如：麦克风

- 传输双声道数据：I2S

- 传输两个及以上声道的数据：TCM

**PCM vs PDM：**

- PCM：
  
  - 使用等间隔采样方法：将每次采样的模拟分量幅度表示为N位的数字分量（N = 量化深度）

  - 每次采样的结果都是 N bit 字长的数据

  - 逻辑更加简单

  - 需要用到数据时钟，采样时钟和数据信号三根信号线

- PDM：

  - PDM采样的音频数据 也常被叫做：Oversampled 1-bit Audio

  - 使用远高于PCM采样率的时钟采样调制模拟分量

  - 只有1位输出：要么为0，要么为1

  - 逻辑相对复杂

  - 只需要两根信号线，即时钟和数据

- AC'97
  - 还具有控制功能

  - 不只是一种数据格式：用于音频编码的内部架构规格

  - 比I2S优点：明显减少了整体管脚数

  - 一般来说，`AC'97` 编解码器采用 TQFP48 封装

- USB
  - 不管用的什么接口，传输的都是PCM或者PDM编码的数字音频
  - 在很多外接的音频模块上，用的是USB音频
  - 科大讯飞的多mic降噪模块，用的就是usb接口，方便调试


#### cpu_dai

驱动通常对应 cpu 的一个或者几个 I2S/PCM 接口。用来连接 platform 和 machine。不同的声卡有不同的 cpu_dai 。

#### Linux 内存映射函数 mmap 函数

将用户空间的一段内存区域映射到内核空间，映射成功后，用户对这段内存区域的修改可以直接反映到内核空间，同样，内核空间对这段区域的修改也直接反映用户空间。那么对于内核空间<---->用户空间两者之间需要大量数据传输等操作的话效率是非常高的。

