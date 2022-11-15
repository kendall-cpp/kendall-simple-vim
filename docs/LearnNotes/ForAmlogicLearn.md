# kernel Kconfig defconfig .config

**一般情况：**

- defconfig 一般在arch/arm64/configs/目录下，是一个没有展开的内核配置，需要配合Kconfig展开成 .config

- 从 defconfig 到 `.config` 不是简单的复制操作，而是 make ARCH=arm64 defconfig

- `.confg` 也不是直接拷贝成 defconfig ，而是使用 make ARCH=arm64 savedefconfig

正确使用和保存deconfig的流程：
- 1. 要修改在 arch/arm/configs 下的文件 xxx_defconfig （芯片官网） （编译时会去读取 Kconfig 找到 xxx_defconfig)
- 2. make ARCH=arm64 xxx_defconfig 会生成 `.config` 文件
- 3. make ARCH=arm64 menuconfig 修改配置后保存（设置 `.config`）
- 4. make ARCH=arm64 savedefconfig 生成 defconfg 文件
- 5. cp defconfig arch/arm/configs/xxx_defconfig 保存
这样保存的 defconfig 文件，配置最小化，且日后能恢复成 `.config` 。

> make menuconfig ---- 从Kconfig中读出配置菜单 保存到 `.config`

### 以添加一个具体驱动为例

- 找到 arch/arm64/configs/aplex_cmi_aa158_defconfig（这个可以从芯片官网下载）
- 修改配置
- 编译配置

make aplex_cmi_aa158_defconfig ARCH=arm64

> 就是把 arch/arm64/configs/aplex_cmi_aa158_defconfig 里面的配置写到了 Linux 代码目录下的 .config 文件里面。

- 执行 make menuconfig ARCH=arm64 , make menuconfig 操作就是把 .config 文件里面的配置读取出来，然后显示在一个可视化的界面里，在可视化界面修改后会重新写会到 .config 中。

- 保存配置 make savedefconfig  ARCH=arm64

> 执行完毕之后，会生成一个保存的配置文件为： `defconfig`

- 再把 defconfig 文件配置覆盖先前的配置

cp  defconfig  arch/arm64/configs/aplex_cmi_aa158_defconfig -rf 

## Amlogic config

和普通的defconfig不同，Amlogic 的 defconfig 是没有隐藏依赖的，直接 make menuconfig 生成 .config , 然后和 defconfig 对比，然后拷贝即可，使用 build_kernel 编译的时候会去 diff defconfig 和 `.config` 。


---

# freertos

## xTaskCreat相关函数的使用

```c
 BaseType_t xTaskCreate(    TaskFunction_t pvTaskCode,  //指向任务函数，一般是个死循环
                            const char * const pcName,  //任务函数的别名
                            configSTACK_DEPTH_TYPE usStackDepth, //任务栈大小
                            void *pvParameters,					// 任务函数的参数，不需要传参设为NULL即可
                            UBaseType_t uxPriority, 			// 任务优先级
                            TaskHandle_t *pxCreatedTask			//实际是一个指针，也是任务的任务堆栈
                          );


```

示例：

```c
xTaskCreate(vStart_AudioTask, "audio_task", configMINIMAL_STACK_SIZE * 2, NULL, 3, NULL);
```



- 其他函数参考

> https://www.w3cschool.cn/freertoschm/freertoschm-strb2u7m.html

## vTaskStartScheduler

**FreeRTOS是通过vTaskStartScheduler()函数来启动运行的**

1. xTaskCreate() 创建空闲任务，其优先级为最低：0；
2. 关闭中断功能，使能任务调度功能；
3. 宏定义portCONFIGURE_TIMER_FOR_RUN_TIME_STATS：系统运行时间统计初始化；
4. 设置系统节拍定时器，并启动第1个任务；
5. 返回空闲任务句柄。

---

# uboot

> 三星的芯片启动机制

## 6410 启动机制
  
上电以后先启动片内的 iROM(BL0) 程序，这部分的程序主要做两件事情
- 初始化时钟，看门狗等一些外围信息
- 第二件事是把 flash 的头 4K 的内容处理成 BL1 , 然后加载到片内 RAM（静态SRAM 16k） 当中去运行，bl1 很小，只能做很简单的事情，主要是配置好 DDR 的主存，主存一般有 512M，配置完主存之后就把 bootloader 剩下的大部分 处理成 bl2 并加载到主存当中，然后再把程序的入口跳转到主存当中的 bl2 位置进行运行（bl2就是主要的 bootloader), bl2 会把 flash 中的 OS 镜像加载到主存当中，然后将程序跳转到 OS 入口处运行，这样就完成这个 boot 的过程。

整个 bootloader 头 4k 的内容是加载到片内去运行的，剩下的（比如200k）大部分是加载到主存(动态DDR内存，SDRAM）中去运行，这 4k + 200k 就是 uboot.bin .

## S5PV210启动机制

V210 做了两方面的改进
- 增加了片内 IRAM 的大小，这样的话就把固件的函数做进去，比如读取 flash 的函数，读取 MMC 的函数，
- 增加片内 RAM（SRAM）的大小（86k),这样做的目的是为了让 bl2 也加载到 SRAM 中运行，这样就不用局限于 4k 或者 16k 的地址了，可以在 bl2 中去配置 SDRAM 和一些初始化 SDRAM 工作。再把 OS 加载到 SDRAM 中去运行。

### uboot设计

但是 uboot.bin ，一般都有100多k，SRAM 96k 是装不下的，所以 uboot.bin 一分为二，一部分 uboot-spl.bin(16k), 剩下的 uboot.bin (210k左右)。

上电后，将 uboot-spl.bin(16k) 加载到片内 SRAM 中，然后去配置 SDRAM ，再把 uboot.bin 加载到 SDRAM，然后跳到 SDRAM 的 uboot.bin 入口运行。

> 另外可以参考：[uboot启动流程详细分析](https://blog.csdn.net/maybeYoc/article/details/122937844?spm=1001.2101.3001.6650.15&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-15-122937844-blog-53234020.pc_relevant_aa_2&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-15-122937844-blog-53234020.pc_relevant_aa_2&utm_relevant_index=23)

## uboot.bin

uboot.bin 分成：uboot.bin 和 uboot-spl.bin(64k)

上电--> 将 bl0（64k） 拷贝到 iRAM（片内）运行，在片内完成初始化时钟和看门狗等和配置主存（DDR），然后将 flash 其余的  bootloader 拷贝到 DDR 中，然后把程序入口跳到主存（bl2)运行，bl2 再把 flash 的 OS 拷贝到 DDR，在将程序入口跳到 OS 入口处运行。

- uboot 编译

- make xxx_config 
  - start.S -- .o
  - xxx.c   -- .o
    - 所有的 .o 文件链接成 u-boot (带有调试信息的可执行程序，但是不能在板子上执行)
    - 需要去掉调试信息生成一个 u-boot.bin ，然后烧到板子中运行

## uboot驱动模型


- 配置文件

./board/amlogic/defconfigs/c2_spencer_p2_defconfig

- CONFIG_DM=y，全局 DM 模型打开
- CONFIG_DM_XXX=y，某个驱动的DM模型的打开
- 可以通过Kconifg、Makefile来查看对应宏的编译情况

```c
include/asm-generic/global_data.h
26:typedef struct global_data {
```

其中 dm_root_f，uclass_root用来管理整个 DM 模型。

- dm_root：DM 模型的根设备
- dm_root_f：重定向前的根设备
- uclass_root：uclass链表的头

这几个变量，最终要的作用就是：管理整个模型中的 udevice 设备信息和 uclass 驱动类。

> include/dm/uclass.h

- uclass，来管理该类型下的所有设备，并且有对应的 uclass_driver 驱动。
  - 所有生成的 uclass 都会被挂载 `gd->uclass_root` 链表上。

- uclass_driver： 它就是 uclass 的**驱动程序**。其主要作用是：**为 uclass 提供统一管理的接口**
  - uclass_driver 主要通过 `UCLASS_DRIVER (include/dm/uclass.h)` 来定义
  - 比如：`UCLASS_DRIVER(pinctrl) {}`
  - 相关的 API 主要作用根据 uclass_id ，查找对应的 uclass，然后根据索引值或者名称，来查找到对应的udevice

- 将 udevice(设备) 连接到对应的 uclass 中，uclass 主要用来管理着同一类的驱动
  - 除此之外，有父子关系的 udevice ，还会连接到 `udevice->child_head` 链表下

**在 dtb 中解析 uclass（某一设备类型） 和 udevice(某一设备）**，类似这样的函数（ `device_bind_by_name` ）

![](https://img-blog.csdnimg.cn/img_convert/becda76e7db7284e42b5146517821dcc.png)

- driver 对象（驱动对象），主要通过 U_BOOT_DRIVER 来定义 

```c
U_BOOT_DRIVER(xxx_pinctrl) = {}
```

![](https://img-blog.csdnimg.cn/img_convert/1674ba2addfcc0c4baf0402e8a4099be.png)


> **uclass（某一类型的设备） -- udevice（某一个设备） -- uclass_driver（操作设备的驱动的 API） -- driver(某一个设备的驱动)**

### lists_bind_fdt

我们通常会使用设备树来定义各种设备,这个函数主要用来查找子设备，并且根据查找到的子设备，进而查找对应驱动进行绑定！ 即：实现了 driver 和 device 的绑定。

lists_bind_fdt 这个函数，主要用来扫描设备树中的各个节点；

根据扫描到的 udevice 设备信息，通过 compatible 来匹配 compatible 相同的 driver ，匹配成功后，就会创建对应的 struct udevice 结构体，它会同时指向设备资源和 driver ，这样设备资源和 driver 就绑定在一起了。

### DM模型-probe探测函数的执行

dm_init 只是负责初始化并绑定了 udevice 和 driver，probe 探测函数的执行，是在该驱动初始化的时候

在 MMC 驱动初始化后，有没有注意到 mmc_probe 这个函数，该函数就是间接调用了我们驱动编写的 probe 函数。mmc_probe 执行流程 根据 uclass_id，调用 uclass_get_device_by_seq 来得到 udevice，进而调用device_probe 来找到对应驱动的 probe。

![](https://pic1.zhimg.com/v2-13bbe1e45a6ee30e546e1dd3c99e2b0c_r.jpg)

- 根据 udevice 获取driver
- 然后判断是否父设备被 probe
- 对父设备进行probe
- 调用driver的probe函数


---

# 需要研究的知识点

## GPIO子系统



## 中断子系统

http://www.wowotech.net/sort/irq_subsystem

## 电源管理子系统

http://www.wowotech.net/sort/pm_subsystem

## USB 子系统

### USB控制器

## MBP源码

### 海思的 MPP

> https://www.zhihu.com/column/technoteofxiaobei

MPP核心的几大模块：

- 负责视频输入的VI模块
- 负责视频输出的VO模块
- 负责视频中间处理的VPSS模块
- 负责视频编码的VENC模块
- 负责视频解码的VDEC模块
- 负责图形处理的VGS模块
- 负责音频处理的AUDIO模块


#### MIPI 

https://blog.csdn.net/dkmknjk/category_10960446.html

## camera架构

https://deepinout.com/android-camera/android-camera-system-intro.html

https://deepinout.com/mtk-camera-driver/introduction-to-camera-module-and-hardware-structure.html




