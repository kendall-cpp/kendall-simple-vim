

---

## 嵌入式linux系统启动过程

(1)部署：uboot 程序部署在 Flash（能作为启动设备的Flash）上、OS 部署在 FLash（嵌入式系统中用Flash代替了硬盘）上、内存在掉电时无作用，CPU 在掉电时不工作。

(2)启动过程：嵌入式系统上电后先执行 uboot、然后 uboot 负责初始化 DDR，初始化 Flash，然后将 kernel 从 Flash 中读取到 DDR 中，然后启动 kernel（kernel 启动后 uboot 就无用了）

> 所有的计算机系统运行时需要的主要核心部件都是3个东西：

**CPU + 外部存储器（Flash/硬盘） + 内部存储器（DDR SDRAM/SDRAM/SRAM）**

## 认识 bootloader

首先开发板上电以后芯片会在固化好的一个地址寻找第一个启动程序（在有操作系统的时候，这个引导程序也叫做 bootloader）,完成初始化工作,然后转跳到预定的一个地址来执行裸机程序（没有的操作系统嵌入式系统到这儿就算是启动成功）或者 UBOOT 程序。

> bootloder 可以分为 boot 和 loader 两个部分来实现相应的功能

### boot

- 1、关闭看门狗， 中断 ， MMU ， cache（关掉这些的原因，主要是由于系统处于一些启动状态，不需要这种优化操作如看门狗（启动过程中，因为没有及时喂狗，直接重启了，那玩个锤子），cache（启动过程中出现bug，找起来不方便）。而且有些功能是没有准备好的，如 MMU 的地址映射表，中断的中断处理函数）
- 2、配置系统时钟（时钟可是处理器的心脏，当然得先配好）
- 3、配置SDRAM 的控制器（行地址数，列地址数，多少块），
- 4、初始化堆栈（跑程序的必要条件，程序会自动将sp指针指向的地址，当作栈顶指针）

### loader
 
完成初始化工作,然后转跳到预定的一个地址来执行裸机程序（没有的操作系统嵌入式系统到这儿就算是启动成功）或者 UBOOT 程序。

 
## uboot 启动流程简单概述

U-Boot，全称 Universal Boot Loader，是一个主要用于嵌入式系统的引导加载程序，可以支持多种不同的计算机系统结构，其主要作用为：**引导系统的启动**。


- 在 U-boot 完成初始化工作以后，它剩下的唯一工作就是加载并启动 linux 操作系统的 kernel 了（uboot到这里就结束工作了）。当 U-boot 开始从 Flash 加载指定物理地址的操作系统内核以后，U-boot 引导装入程序的使命就到此结束了，接下来系统由 linux 内核接管。


- 当 linux 内核开始启动以后，开始打印各种设备信息，此时做的工作就是**对各个外设驱动及进行初始化**。再执行完这些操作以后就要**开始挂载根文件系统了。**


- 当内核完成挂载文件系统的工作以后，就要开始运行一个启动名为 init 的应用程序。此时，系统便进入了用户空间，在这种操作模式下，将不能再像内核进程中那样直接访问所有的资源权限。这也就解释了我们在编写程序的时候通过内核系统的调用来请求相应的内核服务。

## u-boot中nand flash驱动架构

在 u-boot 启动过程中调用了 nand_init 函数，也就是 nand flash 驱动初始化的入口。

```c
// arch/openrisc/lib/board.c
#ifdef CONFIG_CMD_NAND
	puts("NAND:  ");
	nand_init();                                                                                                                            
#endif
```

从上面的函数中我们可以看到，这个函数被调用的前提条件是 `CONFIG_CMD_NAND` 这个宏被定义，所以想要操作 nand flash ,就需要在 `.config` 文件中定义该宏。

```c
void nand_init(void)
{
	/*  
	* Init board specific nand support
	*/                                                                                                                                     
	nand_info[0].priv = &nand_chip;
	nand_chip.IO_ADDR_R = nand_chip.IO_ADDR_W =
		(void  __iomem *)CONFIG_SYS_NAND_BASE;
	board_nand_init(&nand_chip);

	if (nand_chip.select_chip)
		nand_chip.select_chip(&nand_info[0], 0); 

	/* NAND 上电之后可能需要复位 */
	nand_command(0, 0, 0, NAND_CMD_RESET);
}
```

- nand_info 主要和芯片本身相关，比如记录 nand flash 的大小等等
- nand_chip 这个结构主要记录 nand flash 它的操作相关，比如 read、wirte 等等


```c
 u-boot.lds 
	| --> vector.S(./arch/arm/lib/vectors.S)
	| --> start.S(./arch/arm/cpu/armv7/start.S)
```