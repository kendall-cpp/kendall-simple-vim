# 1.概述
MBP(Media Business Platform)，目的是优化多媒体业务系统的维护成本和方便多人开发媒体业务驱动模块。MBP提供一套基于模块管理组件，当多人进行并行开发媒体业务驱动模块时，只需关注对应模块xxx.h 中的 API即可。

优化C1和C2一些软件问题，跳过传统的alsa，V4L2等接口。使得移植不同的操作系统（Linux/RTOS）很方便。

![mbp01](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp01.5yrereso8mg0.webp)

# 2.MBP框架

系统层次图如下所示：

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp02.3thpboh4e1q0.webp)

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp03.58pxmsm9p940.webp)

MBP包括MBD（媒体业务驱动程序）、MBI（媒体业务接口），MBD基于OSAL，主要由各种媒体驱动程序组成，MBI是每个媒体驱动程序（ioctl）的封装（实际上是在kernel原始API上套一层，如下代码图）。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp04.1hrmdvtqhbq8.webp)

## 2.1 mbp工作pipeline

- **video**

sensor -- 视频输入 -- VPU视频处理 -- VENC视频编码-- 视频输出 -- 屏幕

- **audio**

麦克风 -- 音频输入 -- 音频编码(AENC) -- 音频码流 -- 音频解码(ADEC) -- 喇叭

# 3.MBP Module

## 3.1 module的设计

- （1）模块绑定功能的初始化/退出

初始化部分应该实现在对应的模块驱动的初始化函数中。同理，退出功能应该实现在对应的模块驱动的退出函数中。

- （2）绑定功能的核心结构：binder 

Binder 的核心结构是两个链表

- （3）绑定功能提供给其他驱动调用的接口

通过 module register 注册为私有的驱动模块，并提供对外的驱动层接口，方便其他驱动模块使用。

- （4）绑定功能提供给用户层使用的接口

Linux 上通过一般的 ioctl，提供用户层接口，并将其封装成 MBI 接口。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp05.56p2jvjs92c0.webp)

## 3.2 Module注册

模块管理组件提供一组通用接口，每个驱动模块抽象出与之对应的对外接口，各个模块通过 **模块描述符** 链表进行管理，各个模块以注册的方式加入到 模块描述符 链表中。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp06.1ki338emam0w.webp)

## 3.3 驱动接口

> vendor/amlogic/ipc/mbp/prebuilt/mbd/base/cppi/src/mbd_cppi_init.c

|  内核态对外接口   | 描述  |
|  ----  | ----  |
| cppi_module_init  | 初始化模块 |
| cppi_module_exit  | 去初始化模块 |
| cppi_module_get_name_byid  | 根据模块 ID 获取模块名 |
| cppi_module_get_module_byid  | 根据模块 ID 获取模块描述符 |
| cppi_module_get_func_byid  | 根据模块 ID 获取模块对外接口 |
| cppi_module_stop  | 模块停止 |
| cppi_module_query  | 模块查询 |
| cppi_module_register  | 模块注册 |
| cppi_module_unregister  | 模块注销 |
| cppi_create_proc_entry  |  |
| cppi_remove_proc_entry  |  |
| cppi_device_create  | 创建设备 |
| cppi_device_destroy  | 移除设备 |
| cppi_device_register  | 注册设备 |
| cppi_device_unregister  | 注销设备 |
| cppi_drv_exit  | 退出drv |

## 3.4 Module使用

**Module Bind 的使用可分为三个步骤**

### 3.4.1 注册

- 在业务驱动模块初始化阶段，需要先通过 module register 注册成 MBD (Media Business Driver)
- 在业务驱动模块初始化阶段，需要通过 module bind 注册成为 sender 或者 receiver 或者既是 sender 也是 receiver
- 如果是 sender 即需要提供一个 bind callback 回调函数
- 如果是 receiver 即需要提供 send callback 及 reset callback 两个回调函数

### 3.4.2 绑定

- 用户需要使用用户接口(MBI)来指定两业务模块间的绑定关系
- 绑定的目标对像是两业模块的输入、输出接口 (instance,channel)

### 3.4.3 运行

- 如果某一业务模块的 sender 需要发送数据给它的 receiver ，那么需要调用 module register 提供 send_data()，这样在链表中找到当初注册的回调函数，并执行
- 同上，如某一业务模块的 sender 需要复位它的 receiver，即需要调用 `reset()`
- 业务模块的 sender 是主动的，receiver 是被动的。需要注意一个 sender 的同一个 channel/instance 可以绑定多个 receiver channel，但同一个 receiver channel 只能绑定一个 sender channel。

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp07.4tdgaqgvbli0.webp)

## 3.5 内存管理模块

MBP整套框架都是基于其专有内存进行数据传输、存储的。OS 内存可以用 `free` 命令查看，而 pmz 则使用 `cat /proc/mbp/pmz` 可以查看到系统总共、已使用的、剩余的 pmz，包括每一块已经使用的pmz的使用情况。

```sh
/ # free
              total        used        free      shared  buff/cache   available
Mem:         240240      139552       61568         756       39120       91972
Swap:             0           0           0

/ # cat /proc/mbp/pmz
+---PMZ: PHYS[0x08000000 - 0x0FFFFFFF], GFP=0, nBytes=131072KB, NAME="anonymous"
   |-PMB: PHYS[0x08000000 - 0x0805FFFF], KVIRT=0xD0832000, FLAGS=0x00000001, nBytes=384KB, NAME="isp0-reg"
   |-PMB: PHYS[0x08060000 - 0x08065FFF], KVIRT=0xD0893000, FLAGS=0x00000001, nBytes=24KB, NAME="venc job"
   |-PMB: PHYS[0x08066000 - 0x08066FFF], KVIRT=0xD0AAB000, FLAGS=0x00000001, nBytes=4KB, AME="ge2d_cmd_buffer"
......
```

MBP 提供了一套PMZ的API接口，包括PMZ申请，释放，物理地址和虚拟地址的映射等。

**[关于视频缓存池更详细介绍](https://confluence.amlogic.com/display/SW/MBP+Memory+Usage+Framework+Design?preview=/122798259/122805441/IPC_C3_SDK_MemoryUsageFramework.pdf)**

## 3.6 Audio 模块

Audio 模块包括音频输入（Audio In）、音频输出（Audio Out）、音频编码（Audio encode）、音频解码（Audio decode）、声音质量增强（VQE）。

### 3.6.1音频输入输出API说明


|  API   | function   | 备注 |
|  ----  | ----  | :----  | 
| MBI_AI_SetPubAttr  | 设置AI设置属性 |         |
| MBI_AI_GetPubAttr  | 获取AI设备属性 |         |
| MBI_AI_Enable  | 启用AI设备 |                 |
| MBI_AI_Disable  | 禁用AI设备 |                |
| MBI_AI_SetChnParam  | 设置AI通道参数 |        |
| MBI_AI_GetChnParam  | 获取AI通道参数 |        |
| MBI_AI_EnableChn  | 启用AI通道 |              |
| MBI_AI_DiableChn  | 禁用AI通道 |              |
| MBI_AI_GetFrame  | 获取音频帧 |               |
| MBI_AI_ReleaseFrame  | 释放音频帧 |                     |
| MBI_AI_SetVolume  | 设置AI通道的音量大小 |                        |
| MBI_AI_GetVolume  | 获取AI通道的音量大小 |                        |
| MBI_AI_EnableReSmp  | 启用AI重采样 |                      |
| MBI_AI_DiableReSmp  | 禁用AI重采样 |    | 
| MBI_AI_SetAencAttr  | 设置AI通道编码功能属性 |    | 
| MBI_AI_GetAencAttr  | 获取AI通道编码功能属性 |    | 
| MBI_AI_EnableAenc  | 启用AI通道编码功能 |    | 
| MBI_AI_DisableAenc | 禁用AI通道编码功能 |    | 
| MBI_AI_SetVqeAttr | 设置AI通道的声音质量增强功能相关属性 |  调度接口模块使用libdl库的dlopen; 方式动态加载各大个功能模块。VQE功能模块支持剪裁。 | 
| MBI_AI_GetVqeAttr  | 获取AI通道的声音质量增强功能相关属性 |    | 
| MBI_AI_EnableVqe  | 启用AI通道的声音质量增强功能 |    | 
| MBI_AI_DisableVqe  | 禁用AI通道的声音质量增强功能 |    | 


**音频输出API参考:** https://confluence.amlogic.com/display/SW/Audio+Design

**相关API举例:**


```c
MBP_S32  MBI_AO_SetPubAttr(AUDIO_DEV AoDevId, AO_ATTR_S *pstAttr )
MBP_S32 MBI_AO_SetDecAttr (AUDIO_DEV AiDevId, AO_CHN AiChn,  AO_AdecConfig_t *pstAdecConfig);

/////////////////////////////////////////////
MBP_S32 ret;
AO_ATTR_S stAttr;
AO_AdecConfig_t  stAdecConfig;
AUDIO_DEV AoDevId = 0; //such as, 0=TDM_OUT,  1=ACODEC_DAC,  2=Line out;
AO_CHN AoChn = 0;
 
stAttr.eBitwidth = MBP_AUDIO_BIT_WIDTH_16;
stAttr.eSamplerate = MBP_AUDIO_SAMPLE_RATE_8000;
stAttr.eSoundmode = MBP_AUDIO_SOUND_MODE_MONO;
stAttr.eWorkmode = MBP_AUDIO_MODE_I2S_MASTER;
stAttr.u32PtNumPerFrm = 1024;
stAttr.u32ChnCnt = 1;
 
ret = MBI_AO_SetPubAttr(AoDevId, &stAttr);   // 设置AI设备属性
ret = MBI_AO_GetPubAttr(AoDevId, &stGetAttr);  // 获取AI设备属性
ret = MBI_AO_Enable(AoDevId);                  // 启用AO设备
ret = MBI_AO_EnableChn(AoDevId, AiChn );        //启用AO通道
 
memset(&stAdecConfig, 0x0, sizeof(AO_AdecConfig_t));
stAdecConfig.eAdecType = MBP_AUDIO_ADEC_TYPE_G711A;
stAoSetAdecConfig.stAdecG711Cfg.eSamplerate = MBP_AUDIO_SAMPLE_RATE_8000;
stAoSetAdecConfig.stAdecG711Cfg.eSoundmode = MBP_AUDIO_SOUND_MODE_MONO;
 
ret = MBI_AO_SetDecAttr (AoDevId, AoChn, &stAoSetAdecConfig);
```

### 3.5.1 audio sample测试

- 修改 sample_audio.c 

```c
// test audio MPP
static int test_mpp_read(MBP_U8 dev, MBP_U32 rate,
		MBP_U8 bit_width, MBP_U8 channel) {
#define FN_SIZE 40
	char fn[FN_SIZE], fn1[FN_SIZE];
	MBP_S32 chn = channel;
	MBP_S32 sound_mode = (chn == 1)?AUDIO_SOUND_MODE_MONO:AUDIO_SOUND_MODE_STEREO;
	MBP_U8 bit_depth = (bit_width == 32) ?
			AUDIO_BIT_WIDTH_32 : AUDIO_BIT_WIDTH_16;

	printf("recording output ===> dev%d_%dch_%dkHz_%dbit.pcm", dev, (chn==1)?1:2, rate/1000, bit_width);
	snprintf(fn, FN_SIZE, "dev%d_%dch_%dkHz_%dbit.pcm",
		dev, (chn==1)?1:2, rate/1000, bit_width);
	snprintf(fn1, FN_SIZE, "loopback_lb.pcm");
	FILE *fp = fopen(fn, "w");
	FILE *fp1 = fopen(fn1, "w");

	const AIO_ATTR_T attr = {
		.enSamplerate = rate,
		.enBitwidth = bit_depth,
		.enWorkmode = AIO_MODE_PCM_MASTER_STD,
		.enSoundmode = sound_mode,
		.u32EXFlag = 0, // no expand?
		.u32FrmNum = 500, // <= MAX_AUDIO_FRAME_NUM
		.u32PtNumPerFrm = 10*rate*chn/1000, // 10ms
		.u32ChnCnt = chn,
		.u32ClkSel = 0, // seprated clk
		.enI2sType = AIO_I2STYPE_INNERCODEC,
	};

	MBP_S32 r, ret = 0;
	r = MBI_AI_SetPubAttr(dev, &attr);
	assert(r == 0);

	r = MBI_AI_Enable(dev);
	assert(r == 0);

	r = MBI_AI_EnableChn(dev, 0);
	assert(r == 0);

	/* catch ctrl-c to shutdown cleanly */
	signal(SIGINT, cap_stream_close);

	AUDIO_FRAME_T frm;
	AEC_FRAME_T aec;
	MBP_S32 timeout = 0, volume;
	size_t i, times = 10 * 100; //10 seconds

	MBI_AI_SetVolume(dev, 0, 12);
	MBI_AI_GetVolume(dev, 0, &volume);
	//printf("%s, volume=%d\n", __func__, volume);
	// viraddr0, viraddr1 => interlaver buf
	for (i = 0; (i != times) && cap_close_flag; i++) {
		r = MBI_AI_GetFrame(dev, 0, &frm, &aec, timeout);
		if (r < 0) {
			printf("%s GetFrame failed\n", __func__);
			ret = -1;
			goto ai_err;
		}

		/* MIC data */
		fwrite(frm.u64VirAddr[0], frm.u32OrigPcmLen, 1, fp);

		/* AEC data */
		if (dev == LOOPBACK_MIC) {
			fwrite(aec.stRefFrame.u64VirAddr[0],
				aec.stRefFrame.u32OrigPcmLen, 1, fp1);
		}

		r = MBI_AI_ReleaseFrame(dev, 0, &frm, &aec);
	}

ai_err:
	MBI_AI_DisableChn(dev, 0);
	MBI_AI_Disable(dev);

	if (fp)
		fclose(fp);
	if (fp1)
		fclose(fp1);

	return ret;
}

static int test_mpp_write(char *fn, MBP_U32 sample_rate, MBP_U8 channel) {
	MBP_S32 dev = 0;
	MBP_S32 chn = channel;
	MBP_S32 rate = sample_rate;
	const AIO_ATTR_T attr = {
		.enSamplerate = rate,
		.enBitwidth = AUDIO_BIT_WIDTH_16,
		.enWorkmode = AIO_MODE_PCM_MASTER_STD,
		.enSoundmode = AUDIO_SOUND_MODE_STEREO,
		.u32EXFlag = 0, // no expand?
		.u32FrmNum = 500, // <= MAX_AUDIO_FRAME_NUM
		.u32PtNumPerFrm = 10*rate*chn/1000, // 10ms
		.u32ChnCnt = chn,
		.u32ClkSel = 0, // seprated clk
		.enI2sType = AIO_I2STYPE_INNERCODEC,
	};
	MBP_S32 r, ret = 0;
	r = MBI_AO_SetPubAttr(dev, &attr);
	assert(r == 0);

	r = MBI_AO_Enable(dev);
	assert(r == 0);

	r = MBI_AO_EnableChn(dev, 0);
	assert(r == 0);

	AUDIO_FRAME_T frm;
	MBP_S32 timeout = 0;
	MBP_S32 i, times = 50 * 100, volume; // 50 seconds
	size_t frame_size = attr.u32PtNumPerFrm * size_bitwidth(attr.enBitwidth);
	MBP_U8 *buf = malloc(frame_size);

	frm.enBitwidth = attr.enBitwidth;
	frm.enSoundmode = attr.enSoundmode;
	frm.pvVirAddr[0] = buf;
	//frm.pvVirAddr[1] = NULL;
	frm.u64PhyAddr[0] = frm.u64PhyAddr[1] = 0; // no physical address
	frm.u64TimeStamp = 0; // TODO
	frm.u32Seq = 0; // TODO
	frm.u32OrigPcmLen = frame_size;
	frm.u32Len = frame_size;
	frm.u32PoolId[0] = frm.u32PoolId[1] = 0; // TODO

	/* catch ctrl-c to shutdown cleanly */
	signal(SIGINT, play_stream_close);

	FILE *fp = fopen(fn, "rb");
	if (!fp) {
		printf("Unable to open file '%s'\n", fn);
		ret = -1;
		goto ao_err;
	}

	MBI_AO_SetVolume(dev, 0, 30);
	MBI_AO_GetVolume(dev, 0, &volume);
	//printf("%s, volume=%d\n", __func__, volume);
	for (i = 0; (i != times) && !play_close_flag; i++) {
		r = fread(buf, frame_size, 1, fp);
		if (r != 1)
			break;
		MBI_AO_SendFrame(dev, 0, &frm, timeout);
	}

ao_err:
	free(buf);
	MBI_AO_DisableChn(dev, 0);
	MBI_AO_Disable(dev);

	if (fp)
		fclose(fp);

	return ret;
}

static void Get_Set_Volume(MBP_U8 dev, MBP_S32 volume) {
	MBP_S32 old_volume;
	MBI_AO_GetVolume(dev, 0, &old_volume);
	printf("%s--%d, volume=%d\n", __func__, __LINE__, old_volume);
	MBI_AO_SetVolume(dev, 0, volume);
	MBI_AO_GetVolume(dev, 0, &old_volume);
	printf("%s--%d, volume=%d\n", __func__, __LINE__, old_volume);
}

int main(int argc, char **argv) {
	MBP_U8 device = 0;
	MBP_U8 bits = 16;
	MBP_U32 rate = 48000;
	MBP_U8 channel = 2;
	MBP_BOOL_E mute = MBP_FALSE;
	char *filename;
	MBP_S8 r = -1;
        
        if(argc < 2) {
                printf("please input write or read !\n");
                return -1;
        }
        argv += 1;
        // record
        if (strcasecmp(*argv, "read") == 0) {
		r = test_mpp_read(device, rate, bits, channel);
        } else if (strcasecmp(*argv, "write") == 0) {  // play
                argv++;
                if (argv != NULL) { 
                        filename = argv[0];
                         printf("=======> now aplay %s \n", filename);
			 r = test_mpp_write(filename, rate, channel);
                }
        } else if (strcasecmp(*argv, "volume") == 0) {  //change volume
                argv++;
                if(argv != NULL)
                        mute = atoi(*argv);
                Get_Set_Volume(device, mute);
        }
        if (r == -1)
                printf("Pls check your command\n");

        return 0;
}
```

- 编译测试

```sh
make sample-rebuild
# 找到编译出来的sample_audio文件
cd c3_buildroot_refapp && find ./output/c3_aw409_refapp_a32_release/ -name "sample_audio" | xargs ls -l

adb push sample_audio /data

# 测试
/ # chmod 777 /data/sample_audio 
# 录音（10秒）
/ # sample_audio read
# 播放录音
/ # ls *.pcm
dev0_2ch_48kHz_16bit.pcm  loopback_lb.pcm
/ # sample_audio write dev0_2ch_48kHz_16bit.pcm
```

## 3.6 venc 视频编码

VENC 模块由编码通道子模块（ VENC）和编码协议子模块（ H.264/H.265/JPEG/MJPEG）组成

通道接收到图像之后，比较图像尺寸和编码通道尺寸：

- 如果输入图像比编码通道尺寸大， VENC 将按照编码通道尺寸大小，调用 VGS 对源图像进行缩小，然后对缩小之后的图像进行编码。
- 如果输入图像比编码通道尺寸小， VENC 丢弃源图像。 VENC 不支持放大输入图像编码。
- 如果输入图像与编码通道尺寸相当， VENC 直接接受源图像，进行编码。

### 3.6.1 venc sample测试

将 YUV 数据编码成 H264

> **注意，默认只支持图片格式为nv12的YUV文件**

```sh
adb push .\sample_venc /data

adb push Z:\workspace\C3-file\yuv420p_320x240.yuv /data

# width: 448
# height: 960
# encType: H.264: 96; H.265: 265; JPEG: 26;
# profile: 
# fps: 24 30 60    # 帧率： 
# gop: 25          # 1帧间隔
# rcMode: 
# bitrate: 16000
/data/sample_venc /data/encoder_test_video320x180_nv12_14.yuv 320 180 96 100 24 25 3 16000
# 默认输出路径为 /mnt/chn0.bin
```

使用 eseye_u 工具查看编码后的h.264文件.

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp08.42ep25q5wo20.webp)

## 3.7 vpu module 

视频处理单元

**相关 API 的说明**： https://confluence.amlogic.com/display/SW/C3_VPP?preview=%2F209274183%2F209275908%2FAML+VPU+MBI.pdf

# 4. refApp使用

## 4.1 c3_buildroot_refapp编译与问题解决

### 4.1.1编译C3 buildroot

```sh
source setenv.sh
# 选择409
56. c3_aw409_a32_release  # 没有refapp
57. c3_aw409_refapp_a32_release  
```

### 4.1.2 修复无法使用adb问题

添加补丁： https://scgit.amlogic.com/#/c/270669/

```sh
cd /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/output/c3_aw409_refapp_a32_release/build/linux-amlogic-5.15-dev/common_drivers
ln -s /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/.repo/projects/kernel/aml-5.15/common_drivers.git .git


cd /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/kernel/aml-5.15/common_drivers
git fetch ssh://shengken.lin@scgit.amlogic.com:29418/kernel/common_drivers refs/changes/69/270669/6 && git cherry-pick FETCH_HEAD

make linux-rebuild
make mbd-adla-rebuild 
make mbd-audio-rebuild 
make mbd-base-rebuild 
make mbd-camera-rebuild 
make mbd-cve-rebuild 
make mbd-dewarp-rebuild 
make mbd-ge2d-rebuild 
make mbd-ppu-rebuild 
make mbd-region-rebuild 
make mbd-venc-rebuild 
make mbd-vpu-rebuild  
make pmz-rebuild

make
```

### 4.1.3 解决网络问题

#### 4.1.3.1 网线直连

如果网线直连无法获取IP，尝试使用以下命令自动获取IP。

```sh
dhcpcd eth0   # 自动获取IP
```

#### 4.1.3.2 配置wifi

```sh
wpa_cli -iwlan0 remove_network 0
wpa_cli -iwlan0 add_network 0
wpa_cli -iwlan0 set_network 0 ssid '"Amlogic-vpn04_5G"'
wpa_cli -iwlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -iwlan0 set_network 0 psk '"Aml1234566"' 
wpa_cli -iwlan0 set_network 0 pairwise CCMP
wpa_cli -iwlan0 set_network 0 group CCMP
wpa_cli -iwlan0 set_network 0 proto RSN
wpa_cli -iwlan0 enable_network 0
wpa_cli -iwlan0 status
wpa_cli -iwlan0 save

dhcpcd wlan0   # 自动获取 wifi 网卡 IP
```

### 4.1.4 修复 ipc_alarm_pld 编译错误

```
c3_aw409_refapp_a32_release/build/ipc-reference-1.0/modules/alarm/src/ipc_alarm_pld.c:171:86: error: request for member ‘rect’ in something not a structure or union
```

最新的C3-SDK暂时未修复该问题，可以通过checkout 到上一个 commit 解决。


```sh
# /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/vendor/amlogic/ipc/refapp/src
# 最新的是 commit id : af5a893738d9ba8372bee88fd141f4a7213e2763
git checkout 875e347a447e9bae8329392e7eee8e006d8b3c44

# /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/vendor/amlogic/ipc/mbp/prebuilt
# 最新的是 commit id : 87552832d73c94d9bf8d7739f4bff5d73c422f69
git checkout 29a9ddfcba947984e19e079c73e9a7f2f572a9cf

make mbi-rebuild
make ipc-reference-rebuild
make
```


## 4.2 启动和停止refApp

```sh
/etc/init.d/S81ipc-refapp  stop    # 停止
/etc/init.d/S81ipc-refapp  start    # 启动
ifconfig
# inet addr:10.28.39.22
```

通过浏览器访问 10.28.39.22
- 账户：admin
- 密码：admin

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp09.3cqwn8qeo1y0.webp)


**最终效果图**

![](https://cdn.staticaly.com/gh/kendall-cpp/blogPic@main/blog-01/mbp10.ae6gtjhd5g4.webp)