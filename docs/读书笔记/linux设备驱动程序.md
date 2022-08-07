
------

## 环境搭建

安装好 ubuntu，查看自己的 kernel 版本，

```
uname -r
```

通过 [这里](https://mirrors.edge.kernel.org/pub/linux/kernel/v3.0/) 这里可以下载 kernel。

将下载好的 kernel 源码上传到 ubuntu 中，比如： /home/`/usr/src/linux-3.13`

### 配置内核

使用 sudo make oldconfig，然后一路回车到结束。

### 编译

sudo make

报错

```
cc1: error: code model kernel does not support PIC mode
/usr/src/linux-3.13/./Kbuild:35: recipe for target 'kernel/bounds.s' failed
make[1]: *** [kernel/bounds.s] Error 1
Makefile:859: recipe for targe
```

原因是：环境变量（交叉编译路径）可能是在普通用户下添加的，所以在root用户下创建的文件使用 arm-linux-gcc 编译的时候，找不到 arm-linux-gcc。

----

# 编译内核

## 国内下载 kernel

https://mirror.bjtu.edu.cn/kernel/linux/kernel/

我下载的是 linux-5.6.14.tar.gz

## 编译

可以通过 uname -a 查看当前系统 kernel 版本

使用内置图像化界面进行配置

sudo make menuconfig

可能需要安装一些工具

sudo apt-get install libncurses-dev

sudo apt-get install flex

sudo apt-get install bison build-essential



进入图形界面后

直接 EIXT --> YES

配置文件会保存在 `.config` 中，

开始执行 sudo make 进行编译

需要安装一些库文件

sudo apt install libssl-dev

继续：sudo make -j4  

### 生成和构建设备树

sudo make modules_install

报错

```
sed: can't read modules.order: No such file or directory
Makefile:1307: recipe for target '_modinst_' failed
make: *** [_modinst_] Error 2
```

解决

```
sudo make V=1 all
```

报错

```
need-builtin=1 need-modorder=1
make[1]: *** No rule to make target 'debian/canonical-certs.pem', needed by 'certs/x509_certificate_list'.  Stop.
Makefile:1691: recipe for target 'certs' failed
make: *** [certs] Error 2
```

继续执行 sudo make V=1 all

报错

```
recipe for target 'vmlinux' failed
```

sudo apt-get install lzop

还有将 .config 修改

```sh
CONFIG_DEBUG_INFO_BTF: = y # 改成
#CONFIG_DEBUG_INFO_BTF is not set
```

执行 sudo  make -j4

sudo make modules_install -j4

### 安装 kernel

sudo make install

### 验证

设置开机出现引导选项

sudo vim /etc/default/grub

注释掉下面一行，
将 GRUB_TIMEOUT 的值修改为 20
将  GRUB_CMDLINE_LINUX_DEFAULT 的值修改为 text

如下所示

```sh
GRUB_DEFAULT=0
#GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=20
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
# GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX_DEFAULT="text"
```


重启系统

选择第二项：Advanced options for Ubuntu 看到我们编译的内核表示成功



### 测试

cd /home/book/kenspace/linux

vim test.c

```c
#include <linux/init.h>
#include <linux/module.h>
MODULE_LICENSE("Dual BSD/GPL");
                          
static int test_init(void)
{                         
            printk(KERN_ALERT "Hello World.\n");
                          
                return 0;
                          
}                         
                          
static void test_exit(void)
{                         
            printk(KERN_ALERT"Exit.\n");
                          
}                         
                          
module_init(test_init);
module_exit(test_exit);
```

vim Makefile

```mk
obj-m:=test.o                                                                                                                                 
 
KERNELDIR:=/lib/modules/$(shell uname -r)/build
PWD:=$(shell pwd)
 
modules:
        $(MAKE) -C $(KERNELDIR) M=$(PWD) modules
clean:
        rm -rf *.o *.ko
```


执行 make

```sh
book@kendall:~/kenspace/linux$ sudo insmod ./test.ko 
[sudo] password for book: 
book@kendall:~/kenspace/linux$ sudo rmmod test
book@kendall:~/kenspace/linux$ sudo dmesg -c | grep Hello
[  511.099875] Hello World.
book@kendall:~/kenspace/linux$ sudo dmesg -c | grep Exit
book@kendall:~/kenspace/linux$ sudo dmesg -c | grep Hello
book@kendall:~/kenspace/linux$ sudo dmesg -c | grep Exit
```
----



