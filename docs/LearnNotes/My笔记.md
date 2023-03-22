

# 使用 qemu+GDB 调试kernel源码

> 参考：https://blog.csdn.net/sinat_32705609/article/details/128306446

## 安装编译工具链

由于Ubuntu是X86架构，为了编译arm64的文件，需要安装交叉编译工具链

```sh
sudo apt-get install gcc-aarch64-linux-gnu

sudo apt-get install libncurses5-dev  build-essential git bison flex libssl-dev
```

**建议使用源码安装**

去 https://releases.linaro.org/components/toolchain/binaries/ 这里下载各种交叉编译器

将编译器上传到 ubuntu ，然后拷贝到 `/usr/local/arm` 目录中并对其进行解压。

```sh
wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-i686_aarch64-linux-gnu.tar.xz
sudo tar -xf gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz 
```

然后配置环境变量

```sh
sudo vim /etc/profile

export PATH=$PATH:/usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin
```

## 制作根文件系统

使用 busybox 制作根文件系统

可以直接去官网下载 busybox： https://busybox.net/

这里使用的是 [BusyBox 1.36.0](https://busybox.net/downloads/busybox-1.36.0.tar.bz2) 版本

```sh
cd filesystem
tar -xjf busybox-1.36.0.tar.bz2 
```

- 修改 Makefile，添加交叉编译器

```mk
--- a/Makefile
+++ b/Makefile
@@ -188,6 +188,8 @@ SUBARCH := $(shell echo $(SUBARCH) | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ \
                                         -e s/ppc.*/powerpc/ -e s/mips.*/mips/ )
 
-ARCH ?= $(SUBARCH)
+CROSS_COMPILE ?= /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-  
+ARCH ?= arm
 
```

- busybox 中文字符支持

```c
--- a/libbb/printable_string.c
+++ b/libbb/printable_string.c
@@ -28,8 +28,6 @@ const char* FAST_FUNC printable_string2(uni_stat_t *stats, const char *str)
                }
                if (c < ' ')
                        break;
-               if (c >= 0x7f)
-                       break;
                s++;
        }
 
@@ -42,7 +40,7 @@ const char* FAST_FUNC printable_string2(uni_stat_t *stats, const char *str)
                        unsigned char c = *d;
                        if (c == '\0')
                                break;
-                       if (c < ' ' || c >= 0x7f)
+                       if (c < ' ')
                                *d = '?';
                        d++;
                }
diff --git a/libbb/unicode.c b/libbb/unicode.c
index e98cbbf..677db1f 100644
--- a/libbb/unicode.c
+++ b/libbb/unicode.c
@@ -1027,7 +1027,7 @@ static char* FAST_FUNC unicode_conv_to_printable2(uni_stat_t *stats, const char
                                        while ((int)--width >= 0);
                                        break;
                                }
-                               *d++ = (c >= ' ' && c < 0x7f) ? c : '?';
+                               *d++ = (c >= ' ') ? c : '?';
                                src++;
                        }
                        *d = '\0';
@@ -1035,7 +1035,7 @@ static char* FAST_FUNC unicode_conv_to_printable2(uni_stat_t *stats, const char
                        d = dst = xstrndup(src, width);
                        while (*d) {
                                unsigned char c = *d;
-                               if (c < ' ' || c >= 0x7f)
+                               if (c < ' ')
                                        *d = '?';
                                d++;
                        }
```


- 配置 busybox

make defconfig

出现 .config 说明配置成功，但是这只是默认配置，可以通过图形界面进行配置

```sh
book@kendall:busybox-1.29.0$ make menuconfig

Location:
-> Settings
-> Build static binary (no shared libs)   (不要选中)

# 继续配置如下路径配置项

Location:
-> Settings
-> [*]   vi-style line editing commands

# 继续配置如下路径配置项

Location:
-> Linux Module Utilities
-> [ ] Simplified modutils 

# 继续配置如下路径配置项

Location:
-> Linux System Utilities
-> mdev (16 kb) //确保下面的全部选中，默认都是选中的

# 最后就是使能 busybox 的 unicode 编码以支持中文

Location:
-> Settings
->  [*] Support Unicode          # 选中
-> [*]   Check $LC_ALL, $LC_CTYPE and $LANG environment variables   # //选中
```


- 现在可以编译 busybox 了

COFIG_PREFIX 指定编译结果的存放目录

```sh
book@kendall:busybox-1.29.0$ make install CONFIG_PREFIX=/home/book/kenspace/filesystem/rootfs

book@kendall:rootfs$ ls
bin  linuxrc  sbin  usr
```

编译完成以后会在 busybox 的所有工具和文件就会被安装到 rootfs 目录中，rootfs 目录下有 bin、sbin 和 usr 这三个目录，以及 linuxrc 这个文件。前面说过 Linux 内核 init 进程最后会查找用户空间的 init 程序，找到以后就会运行这个用户空间的 init 程序，从而切换到用户态。如果 bootargs 设置 `init=/linuxrc`，那么 linuxrc 就是可以作为用户空间的 init 程序，所以用户态空间的 init 程序是 busybox 来生成的。

### 向根文件系统添加 lib 库

- 向 rootfs 的“/lib”目录添加库文件

Linux 中的应用程序一般都是需要动态库的，当然你也可以编译成静态的，但是静态的可执行文件会很大。如果编译为动态的话就需要动态库，所以我们需要向根文件系统中添加动态库。在 rootfs 中创建一个名为“`lib`”的文件夹:  `mkdir lib`

lib 库文件从交叉编译器中获取，前面我们搭建交叉编译环境的时候将交叉编译器存放到了“`/usr/local/arm/`”目录中。交叉编译器里面有很多的库文件，

```sh
#动态库
cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/*so* /home/book/kenspace/filesystem/rootfs/lib/ -d

# 静态库
cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/*.a* /home/book/kenspace/filesystem/rootfs/lib/ -d
```

需要将 `ld-linux-armhf.so.3 -> ld-2.19-2014.08-1-git.so*` 软连接改成真正的**源文件**

```sh
rm -rf /home/book/kenspace/filesystem/rootfs/lib/ld-linux-armhf.so.3

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/lib/ld-linux-armhf.so.3 /home/book/kenspace/filesystem/rootfs/lib/
```

还需要拷贝其他 so 和 .a 文件。

```sh
cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/lib/*so* /home/book/kenspace/filesystem/rootfs/lib -d

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/lib/*.a* /home/book/kenspace/filesystem/rootfs/lib/ -d
```

- 向 rootfs 的“usr/lib”目录添加库文件

在 rootfs 的 usr 目录下创建一个名为 lib 的目录

```sh
mkdir usr/lib

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/usr/lib/*so* /home/book/kenspace/filesystem/rootfs/usr/lib/ -d

cp /usr/local/arm/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc/usr/lib/*.a* /home/book/kenspace/filesystem/rootfs/usr/lib/ -d

# 查看文件夹大小
$ du lib usr/lib -sh
57M     lib
67M     usr/lib
```

- 创建其他文件夹

在根文件系统中创建其他文件夹，如 dev、proc、mnt、sys、tmp 和 root 等

```sh
book@kendall:rootfs$ mkdir dev proc mnt sys tmp root
```


## 编译 kernel


make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- defconfig


默认 ./arch/arm/configs/multi_v7_defconfig

sudo cp filesystem/rootfs ./kernel/linux-5.4/root -r

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig 

make ARCH=arm Image -j8  CROSS_COMPILE=arm-linux-gnueabihf-



- error


gzip: stdout: No space left on device
E: mkinitramfs failure cpio 141 gzip 1


sudo mount /dev/sda1 /boot/

https://www.jianshu.com/p/3a61071ee578



# UAC音频驱动


## tdm_bridge

uac  -- | aplay 应用截取音频 -- tdm  -- 声卡

uac -- tdm_bridge --tdm -- 声卡 

- 普通的 UAC 流程

音频数据从 USB 传递进来，通过 u_audio_start_capture 不停地抓取请求的数，然后由 u_audio_iso_complete 进行处理和送至 dam_buf 中。请求的数据包存在 `usb_request *req` 结构体中，

```c
struct usb_request {
        void *buf;                                  //数据缓存区
        unsigned length;                          //数据长度
        dma_addr_t dma;                        //与buf关联的DMA地址，DMA传输时使用
        unsigned no_interrupt:1;              //当为true时，表示没有完成函数，则通过中断通知传输完成，这个由DMA控制器直接控制
        unsigned zero:1;                          //当输出的最后的数据包不够长度是是否填充0
        unsigned short_not_ok:1;             //当接收的数据不够指定长度时，是否报错
        void (*complete)(struct usb_ep *ep, struct usb_request *req);//请求完成函数
        void *context;                             //被completion回调函数使用
        struct list_head list;                      //被Gadget Driver使用，插入队列
        int status;                                    //返回完成结果，0表示成功
        unsigned actual;                          //实际传输的数据长度
};
```

音频数据主要存在 reg->bug 中，写送到 dam_buf 后，有应用程序比如 aplay 截取音频送到 tdm 中，然后送至声卡。

- tdm_bridge

音频数据从 USB 创建来，在 u_audio_iso_complete 函数中通过 aml_tdm_br_write_data 将 reg->bug 送入 tdm_bridge 中，由 tdm_bridge 送入 tdm 中。接着送到声卡播放。

### 播放流程

- 首先通过 aml_tdm_br_pre_start 打开 tdm_bridge , 调用流程如下

```c
aml_tdm_br_pre_start  // 设置 size 和 rate，保存到 tb_c 结构体中， 后面的 dma_buf.size 就是 size * rate
  aml_tdm_br_work_func  // 如果 tdm_bridge_state != TDM_BR_WORKING
    aml_tdm_br_prepare
    aml_tdm_br_codec_prepare

```

![](https://img-blog.csdnimg.cn/20200309224201427.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2x1Y2t5ZGFyY3k=,size_16,color_FFFFFF,t_70#pic_center)


- aml_tdm_br_dmabuf_avail_space

如果上一次写的地址就是从 ddr 中获取的地址，那就直接给申请到的 dmabuf_size （48000*4），上次写的地址比获取的地址还大，那么 addr + danbuf_size - last_wr_addr ,这种情况就可能出现 buf 不足了，否则如果上次写的地址小于读取的地址，那么就直接返回当前获取的地址 - 上次读取的地址，这种情况很可能出现 space 不足。

```c
if (last_wr_addr > last_rd_addr) {  // 上次写的超过了上次读的，因为是个环形
        if ((dmabuf_end - last_wr_addr) >= len) {
                offset = last_wr_addr - dmabuf_addr;
                memcpy(buf + offset, data, len);
                last_wr_addr = last_wr_addr + len; 
        } else {
                ret = len - dmabuf_end + last_wr_addr;
                offset = last_wr_addr - dmabuf_addr;
                /*copy first part*/
                memcpy(buf + offset, data, len - ret);  // 重头开始写
                /*copy second part*/
                memcpy(buf, data + ret, ret);
                last_wr_addr = dmabuf_addr + ret;   // 从头开始移
        }
}
```


## u_audio_iso_playback_complete 调用栈

```sh
[   16.778878@0]  [ffffffb27f25e7b0+  96][<ffffffe610095478>] dump_backtrace+0x0/0x188
[   16.779831@0]  [ffffffb27f25e810+  32][<ffffffe610095624>] show_stack+0x24/0x30
[   16.780742@0]  [ffffffb27f25e830+  64][<ffffffe610e902cc>] dump_stack+0xc8/0xf0
[   16.781651@0]  [ffffffb27f25e870+  48][<ffffffe610858c18>] u_audio_iso_playback_complete+0x110/0x158
[   16.782789@0]  [ffffffb27f25e8a0+  48][<ffffffe610adf544>] req_done+0xdc/0x110
[   16.783688@0]  [ffffffb27f25e8d0+ 112][<ffffffe610ae2478>] crg_udc_ep_dequeue+0x1c8/0x340
[   16.784706@0]  [ffffffb27f25e940+  48][<ffffffe610840a7c>] usb_ep_dequeue+0x34/0x110
[   16.785670@0]  [ffffffb27f25e970+  64][<ffffffe610859c28>] u_audio_stop_playback+0x98/0x110
[   16.786710@0]  [ffffffb27f25e9b0+  32][<ffffffe61085a724>] afunc_disable+0x2c/0x38
[   16.787654@0]  [ffffffb27f25e9d0+  48][<ffffffe610839580>] reset_config.isra.12+0x48/0x80
[   16.788671@0]  [ffffffb27f25ea00+  48][<ffffffe610839608>] composite_disconnect+0x50/0x80
[   16.789690@0]  [ffffffb27f25ea30+  48][<ffffffe61083d118>] configfs_composite_disconnect+0x88/0x90
[   16.790806@0]  [ffffffb27f25ea60+  96][<ffffffe610ae43d0>] crg_handle_port_status+0x270/0x550
[   16.791867@0]  [ffffffb27f25eac0+  64][<ffffffe610ae4774>] crg_udc_handle_event+0xc4/0x170
[   16.792897@0]  [ffffffb27f25eb00+  96][<ffffffe610ae4974>] process_event_ring+0x154/0x2a8
[   16.793915@0]  [ffffffb27f25eb60+  80][<ffffffe610ae4cdc>] crg_gadget_handle_interrupt+0x214/0x2a8
[   16.795031@0]  [ffffffb27f25ebb0+  32][<ffffffe610ae4d90>] crg_udc_common_irq+0x20/0x30
[   16.796027@0]  [ffffffb27f25ebd0+ 128][<ffffffe610132dc8>] __handle_irq_event_percpu+0x90/0x2e0
[   16.797110@0]  [ffffffb27f25ec50+  48][<ffffffe610133040>] handle_irq_event_percpu+0x28/0x60
[   16.798161@0]  [ffffffb27f25ec80+  48][<ffffffe6101330c4>] handle_irq_event+0x4c/0x80
[   16.799136@0]  [ffffffb27f25ecb0+  48][<ffffffe610138674>] handle_fasteoi_irq+0xb4/0x158
[   16.800144@0]  [ffffffb27f25ece0+  32][<ffffffe610131c0c>] generic_handle_irq+0x34/0x50
[   16.801140@0]  [ffffffb27f25ed00+  64][<ffffffe610132418>] __handle_domain_irq+0x68/0xc0
[   16.802148@0]  [ffffffb27f25ed40+ 368][<ffffffe610081424>] gic_handle_irq+0xb4/0xd0
[   16.803101@0]  [ffffffb27f25eeb0+  16][<ffffffe610083888>] el1_irq+0x148/0x240
[   16.804000@0]  [ffffffb27f25eec0+ 160][<ffffffe61008162c>] __do_softirq+0xa4/0x410
[   16.804943@0]  [ffffffb27f25ef60+  32][<ffffffe6100c7328>] irq_exit+0xd8/0xe0
```

## afunc_set_alt 调用栈

```sh
[   10.999955@0]  [ffffff91bf25eb20+  96][<ffffffef10095478>] dump_backtrace+0x0/0x188
[   11.000904@0]  [ffffff91bf25eb80+  32][<ffffffef10095624>] show_stack+0x24/0x30
[   11.001815@0]  [ffffff91bf25eba0+  64][<ffffffef10e8f08c>] dump_stack+0xc8/0xf0
[   11.002725@0]  [ffffff91bf25ebe0+  64][<ffffffef1085a8b4>] afunc_set_alt+0x5c/0x148
[   11.003679@0]  [ffffff91bf25ec20+ 144][<ffffffef1083a70c>] composite_setup+0x934/0x1708
[   11.004674@0]  [ffffff91bf25ecb0+  80][<ffffffef1083d1e0>] android_setup+0xc0/0x148
[   11.005629@0]  [ffffff91bf25ed00+  64][<ffffffef10ae3864>] crg_handle_setup_pkt+0xbc/0x218
[   11.006656@0]  [ffffff91bf25ed40+  64][<ffffffef10ae4890>] crg_udc_handle_event+0x98/0x170
[   11.007685@0]  [ffffff91bf25ed80+  96][<ffffffef10ae4abc>] process_event_ring+0x154/0x2a8
[   11.008704@0]  [ffffff91bf25ede0+  80][<ffffffef10ae4e24>] crg_gadget_handle_interrupt+0x214/0x2a8
[   11.009819@0]  [ffffff91bf25ee30+  32][<ffffffef10ae4ed8>] crg_udc_common_irq+0x20/0x30
[   11.010817@0]  [ffffff91bf25ee50+ 128][<ffffffef10132dc8>] __handle_irq_event_percpu+0x90/0x2e0
[   11.011899@0]  [ffffff91bf25eed0+  48][<ffffffef10133040>] handle_irq_event_percpu+0x28/0x60
[   11.012950@0]  [ffffff91bf25ef00+  48][<ffffffef101330c4>] handle_irq_event+0x4c/0x80
[   11.013925@0]  [ffffff91bf25ef30+  48][<ffffffef10138674>] handle_fasteoi_irq+0xb4/0x158
[   11.014933@0]  [ffffff91bf25ef60+  32][<ffffffef10131c0c>] generic_handle_irq+0x34/0x50
[   11.015929@0]  [ffffff91bf25ef80+  64][<ffffffef10132418>] __handle_domain_irq+0x68/0xc0
[   11.016937@0]  [ffffff91bf25efc0+   0][<ffffffef10081424>] gic_handle_irq+0xb4/0xd0
[   11.017890@0]  [ffffffef118a3e20+  16][<ffffffef10083888>] el1_irq+0x148/0x240
[   11.018791@0]  [ffffffef118a3e30+  96][<ffffffef1092d784>] cpuidle_enter_state+0xac/0x598
[   11.019807@0]  [ffffffef118a3e90+  48][<ffffffef1092dcfc>] cpuidle_enter+0x3c/0x50
[   11.020751@0]  [ffffffef118a3ec0+  48][<ffffffef10102284>] call_cpuidle+0x44/0x80
[   11.021681@0]  [ffffffef118a3ef0+  96][<ffffffef1010260c>] do_idle+0x1f4/0x2b8
[   11.022581@0]  [ffffffef118a3f50+  32][<ffffffef1010297c>] cpu_startup_entry+0x2c/0x30
[   11.023567@0]  [ffffffef118a3f70+  32][<ffffffef10e8f360>] rest_init+0xd8/0xe8
[   11.024467@0]  [ffffffef118a3f90+  16][<ffffffef11300bb0>] arch_call_rest_init+0x14/0x1c
[   11.025473@0]  [ffffffef118a3fa0+   0][<ffffffef11301128>] start_kernel+0x4f8/0x514
```