

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