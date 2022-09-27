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

## uboot 启动

uboot.bin 分成：uboot.bin 和 uboot-spl.bin(64k)

上电--> 将 bl0（64k） 拷贝到 iRAM（片内）运行，在片内完成初始化时钟和看门狗等和配置主存（DDR），然后将 flash 其余的  bootloader 拷贝到 DDR 中，然后把程序入口跳到主存（bl2)运行，bl2 再把 flash 的 OS 拷贝到 DDR，在将程序入口跳到 OS 入口处运行。

uboot 编译

- make xxx_config 
  - start.S -- .o
  - xxx.c   -- .o
    - 所有的 .o 文件链接成 u-boot (带有调试信息的可执行程序，但是不能在板子上执行)
    - 需要去掉调试信息生成一个 u-boot.bin ，然后烧到板子中运行

## uboot驱动模型

> 以 elaine-b3

- 配置文件

configs/sm1_elaine_bx_defconfig

- CONFIG_DM=y，全局DM模型打开
- CONFIG_DM_XXX=y，某个驱动的DM模型的打开
- 可以通过Kconifg、Makefile来查看对应宏的编译情况

```c
include/asm-generic/global_data.h
26:typedef struct global_data {
```

其中 dm_root_f，uclass_root用来管理整个 DM 模型。

- dm_root：DM模型的根设备
- dm_root_f：重定向前的根设备
- uclass_root：uclass链表的头

这几个变量，最终要的作用就是：管理整个模型中的 udevice 设备信息和 uclass 驱动类。

> include/dm/uclass.h

- uclass，来管理该类型下的所有设备，并且有对应的 uclass_driver 驱动。
  - 所有生成的uclass都会被挂载gd->uclass_root链表上。

- uclass_driver： uclass类所包含uclass_driver结构体，它就是uclass的**驱动程序**。其主要作用是：为 uclass 提供统一管理的接口
  - uclass_driver主要通过 UCLASS_DRIVER (`include/dm/uclass.h`) 来定义，比如：`UCLASS_DRIVER(pinctrl) {}`

- 将udevice连接到对应的uclass中，uclass主要用来管理着同一类的驱动
  - 除此之外，有父子关系的 udevice，还会连接到 `udevice->child_head` 链表下

相关的API，主要作用就是根据 uclass_id，查找对应的uclass，然后根据索引值或者名称，来查找到对应的udevice

![](https://img-blog.csdnimg.cn/img_convert/becda76e7db7284e42b5146517821dcc.png)

driver对象，主要通过U_BOOT_DRIVER来定义

U_BOOT_DRIVER(xxx_pinctrl) = {}

![](https://img-blog.csdnimg.cn/img_convert/1674ba2addfcc0c4baf0402e8a4099be.png)

- 根据udevice获取driver
- 然后判断是否父设备被probe
- 对父设备进行probe
- 调用driver的probe函数

# 内核源码阅读


参考： https://zhuanlan.zhihu.com/p/471526790

https://zhuanlan.zhihu.com/p/469193712

## kernel启动源码分析

- kernel 的入口： arch/arm64/kernel/head.S

stext -->  __primary_switch --> __primary_switched  --> start_kernel --> init/main.c


- 第一阶段：从入口跳转到 start_kernel 之前的阶段

这个阶段主要由汇编语言实现

- 第二阶段：跳转到 start_kernel


# USB 协议栈

# workqueue