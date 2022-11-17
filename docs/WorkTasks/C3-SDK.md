
> 波特率 921600

# repo sync

```sh
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m br-ipc-c3.xml --repo-url=git://git.myamlogic.com/tools/repo.git

# 用这个
repo init -u git://git.myamlogic.com/linux/manifest.git -b master -m br-ipc-c3-refapp.xml --repo-url=git://git.myamlogic.com/tools/repo.git

# 修改 git user email
# vim buildRoot_C3/.repo/repo/.git/config
[user]   
        name = shengken.lin
        email = shengken.lin@amlogic.com 
repo sync -c   # -c 是指拉取 指定的 xml
```

# 编译

```sh
source setenv.sh 
# 选择AW401
make


```


## 编译uboot

```sh
# 可以用409的bootloader
ls bl33/v2019/board/amlogic/defconfigs/c3_aw409_defconfig 
# 编译
uboot-repo$ ./mk c3_aw409_av400

# 编译kernel
buildRoot_C3$ make linux-dirclean
buildRoot_C3$ make linux-rebuild  
# 编译uboot
# buildRoot_C3$ make uboot-dirclean
buildRoot_C3$ make uboot-rebuild  
```

### buildroot-output

- build 包含所有的源文件，包括 Buildroot 所需主机工具和选择的包，这个目录包含所有 模块源码。
- host 主机端编译需要的工具包括交叉编译工具
- images 含压缩好的根文件系统镜像文件
- staging 这个目录类似根文件系统的目录结构，包含编译生成的所有头文件和库，以及其他开发文件，不过他们没有裁剪，比较庞大，不适用于目标文件系统。
- target 包含完整的根文件系统，对比 `staging/`，它没有开发文件，不包含头文件，二进制文件也经过 strip 处理。

进行编译时，Buildroot 根据配置，会自动从网络获取相关的软件包，包括一些第三方库，插件，实用工具等，放在`dl/`目录。

软件包会解压在 `output/build/` 目录下，然后进行编译

如果要修改软件包的源码，可以通过打补丁的方式进行修改，补丁集中放在 `package/` 目录，Buildroot 会在解压软件包时为其打上相应的补丁

#### buildroot 单独重新编译某个模块

1. 直接删除源码包，例如我们要重新编译 openssh，那么可以直接删除 `output/build/openssh-vesion` 文件夹，那么当你 make 的时候，他就会自动从 dl 文件夹下，解压缩源码包，并重新安装

2. 也是以 openssh 为例子，如果我们不想重新编译，只想重新配置，也就是 `./configure` ，

- 我们可以直接删除 output/build/openssh-version 目录下的 `.stamp_configured`
- 如果你只是想重新安装可以删除 `.stamp_target_install`
- 重新 make 可以删除 `.stamp_built`

```
.stamp_configured,          此文件表示已经配置过
.stamp_downloaded,          此文件表示源码已经下载过，没有此文件会重新下载
.stamp_patched,             此文件表示已经打过补丁
.stamp_extracted            此文件表示已经解压过
.stamp_builted              此文件表示源码已经编译
.stamp_target_installed     此文件表示软件已经安装过
```

注意：修改代码后（不是修改 output 目录下的），不用运行 linux-dirclean，只用 linux-rebuild 即可。Buildroot 会 rsync 将你外部的源码同步到 output/build 并且编译，并且不会删掉上次编译的缓存文件，自动只编译你修改的部分。

#### 打包成 boot.img

```sh
# 在这个脚本
vim output/c3_aw401_a32_release/images/mk_bootimg.sh 

./mk_bootimg.sh    # 打包生成 boot.img
```


```sh
# 设置log 级别
echo 9 > /proc/sys/kernel/printk
echo 0 > /proc/sys/kernel/printk
```

### adb 无法使用问题

添加补丁： https://scgit.amlogic.com/#/c/270669/

```
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

# MBP 熟悉

## 模块注册

模块管理组件为每个驱动模块提供相应的对外接口，不同业务驱动之间通过双方的 ID 相互访问，这样就可以实现两个模块之间的关联

- CPPI：common platform program interface 通用平台程序接口
- MBD：基于 OSAL，主要由各种媒体驱动程序组成

各个模块通过 模块描述符 链表进行管理，各个模块以注册的方式加入到 模块描述符 链表中。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221107194434.png)


## 驱动接口

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


## 模块绑定

通过数据接收者绑定数据源来建立两模块之间的数据流。数据源生成的数据将根据绑定的情况，自动发送给数据接收者，用于描述模块与模块之间的关系。

### 模块绑定的功能设计

- 模块绑定功能的初始化/退出。

初始化部分应该实现在对应的模块驱动的初始化函数中。同理，退出功能应该实现在对应的模块驱动的退出函数中

- 绑定功能的核心结构：binder

Binder 的核心结构是两个链表

- 绑定功能提供给其他驱动调用的接口

通过 module register 注册为私有的驱动模块，并提供对外的驱动层接口，方便其他驱动模块使用

- 绑定功能提供给用户层使用的接口

Linux 上通过一般的 ioctl ，**提供用户层接口，并将其封装成 MBI 接口**。

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221107200736.png)

Module bind 提供给其他驱动调用，接口是以回调形式放在 pstExportFuncs 结构体内。主要分为三类: `register/unregister，send/reset data，get bind info` 。

### 模块的使用

Module Bind 的使用可分为三个步骤

- 注册

  - 在业务驱动模块初始化阶段，需要先通过 module register 注册成 MBD (Media Business Driver)
  - 在业务驱动模块初始化阶段，需要通过 module bind 注册成为 sender 或者 receiver 或者既是 sender 也是 receiver
  - 如果是 sender 即需要提供一个 bind callback 回调函数
  - 如果是 receiver 即需要提供 send callback 及 reset callback 两个回调函数

- 绑定
  - 用户需要使用用户接口(MBI)来指定两业务模块间的绑定关系
  - 绑定的目标对像是两业模块的输入、输出接口 (instance,channel)

- 运行
  - 如果某一业务模块的 sender 需要发送数据给它的 receiver ，那么需要调用 module register 提供 send_data()，这样在链表中找到当初注册的回调函数，并执行
  - 同上，如某一业务模块的 sender 需要复位它的 receiver，即需要调用 reset()
  - 业务模块的 sender 是主动的，receiver 是被动的。需要注意一个 sender 的同一个 channel/instance 可以绑定多个 receiver channel，但同一个 receiver channel 只能绑定一个 sender channel

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221108095600.png)



### Audio Design

#### 概述

Audio 模块包括音频输入（Audio In）、音频输出（Audio Out）、音频编码（Audio encode）、音频解码（Audio decode）、声音质量增强（VQE）。

#### 音频输入

主要实现配置及启用音频输入设备、获取音频帧数据、音频编码、以及声学算法处理等功能。

- 输入设备：TDM_IN, PDM_IN, ACODEC_ADC, Line in。
- 音频编码：G711.a、G711.u、G726。
- 声学算法处理：AEC，ANR，AGC等。

##### 功能模块API

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



#### 音頻輸出

主要实现配置及启用音频输出设备、发送音频帧数据、音频编码、以及声学算法处理等功能。

> 和音频输入类似，参考：https://confluence.amlogic.com/display/SW/Audio+Design

#### 举例

```c
MBP_S32  MBI_AO_SetPubAttr(AUDIO_DEV AoDevId, AO_ATTR_S *pstAttr )
MBP_S32 MBI_AO_SetDecAttr (AUDIO_DEV AiDevId, AO_CHN AiChn,  AO_AdecConfig_t *pstAdecConfig);
```

```c
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

### ge2d 设计

GE2D是基于行扫描模式2D加速器，具有各种功能如像素搬移、alpha混合、帧旋转、缩放、格式转换和颜色空间换

![](https://raw.githubusercontent.com/kendall-cpp/blogPic/main/blog-01/20221108152732.png)

ppu,region,vout,ge2dmbi通过接口调用方式直接使用ge2dmbd接口

> 参考： https://confluence.amlogic.com/display/SW/GE2D++Design

### MBP 视频缓冲池框架设计

https://confluence.amlogic.com/display/SW/MBP+Memory+Usage+Framework+Design


查看内存大小

```
cat /proc/mbp/pmz
```

### venc 模块

#### Video Encode 模块功能介绍

典型的编码流程包括了输入图像的接收、图像内容的遮挡和覆盖、图像的编码、以及码流的输出等过程。

VENC 模块由编码通道子模块（ VENC）和编码协议子模块（ H.264/H.265/JPEG/MJPEG）组成

通道接收到图像之后，比较图像尺寸和编码通道尺寸：

- 如果输入图像比编码通道尺寸大， VENC 将按照编码通道尺寸大小，调用 VGS 对源图像进行缩小，然后对缩小之后的图像进行编码。
- 如果输入图像比编码通道尺寸小， VENC 丢弃源图像。 VENC 不支持放大输入图像编码。
- 如果输入图像与编码通道尺寸相当， VENC 直接接受源图像，进行编码。

REGION 模块支持对图像内容的遮挡和叠加。
完成视频区域管理之后，图像被送入具体协议类型编码通道，完成视频编码，输出码流。

> 启用元素流缓冲区循环模式，支持比特流异步写入和读取  
> 减少视频编码，尤其是在多频道的情况下。

### vpu 

视频处理单元

# refapp

```c
// buildRoot_C3/vendor/amlogic/ipc/reference/refapp/src/ipc_refapp.c
main
IPC_APP_Start()
IPC_NETWORK_Init(&WebCallBack);
IPC_NETWORK_Init
IPC_WEBSERVER_Init
```

## ipc_alarm_pld编译错误

```
c3_aw409_refapp_a32_release/build/ipc-reference-1.0/modules/alarm/src/ipc_alarm_pld.c:171:86: error: request for member ‘rect’ in something not a structure or union
```

```sh
# /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/vendor/amlogic/ipc/refapp/src
# 最新的是 commit id : af5a893738d9ba8372bee88fd141f4a7213e2763
git checkout 875e347a447e9bae8329392e7eee8e006d8b3c44

# /mnt/fileroot/shengken.lin/workspace/c3_buildroot_refapp/vendor/amlogic/ipc/mbp/prebuilt
# 最新的是 commit id : 87552832d73c94d9bf8d7739f4bff5d73c422f69
git checkout 29a9ddfcba947984e19e079c73e9a7f2f572a9cf
```

- 重新编译

```sh
make show-targets
make mbi-rebuild


make ipc-reference-rebuild
make
```



## wpa_cli连接wifi

```
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
dhcpcd wlan0

wpa_cli -iwlan0 remove_network 0
wpa_cli -iwlan0 add_network 0
wpa_cli -iwlan0 set_network 0 ssid '"kendall"'
wpa_cli -iwlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -iwlan0 set_network 0 psk '"12345678"' 
wpa_cli -iwlan0 set_network 0 pairwise CCMP
wpa_cli -iwlan0 set_network 0 group CCMP
wpa_cli -iwlan0 set_network 0 proto RSN
wpa_cli -iwlan0 enable_network 0
wpa_cli -iwlan0 status
wpa_cli -iwlan0 save
```

## 停止 refapp

```sh
/etc/init.d/S81ipc-refapp  stop
```

### 网线直连获取IP

```sh
dhcpcd eth0   # 自动获取 IP

dhcpcd wlan0  # 自动获取 wifi 网卡 Ip
```

### 测试 sample

#### audio

```sh
# 找到编译的 sample
make sample-rebuild
find ./output/ -name "sample_audio" | xargs md5sum

scp Z:\workspace\c3_buildroot_refapp\output\c3_aw409_refapp_a32_release\target\usr\bin\sample_audio root@192.168.137.127:/data/
scp Z:\windowFile\Korlan-SDK文件\audioFile\44100.wav root@192.168.137.127:/data/
```

#### sample_venc

```sh
adb push .\sample_venc /data

# 将 YUV 数据编码成 H264
adb push Z:\workspace\C3-file\yuv420p_320x240.yuv /data

width: 448
height: 960
encType: H.264: 96; H.265: 265; JPEG: 26;
profile: 
fps: 24 30 60   # 帧率： 每妙传输帧数
gop: 25   # I帧间隔
rcMode: 
bitrate: 16000
 /data/sample_venc /data/yuv420p_320x240.yuv 320 240 96 100 60 25 2 16000
/data/sample_venc /data/encoder_test_video320x180_nv12_14.yuv 320 180 96 100 24 25 3 16000
```

