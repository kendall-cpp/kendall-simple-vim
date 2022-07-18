

-----

当 u-boot 开始执行 bootcmd 命令，就进入 Linux 内核启动阶段。普通 Linux 内核的启动过程也可以分为两个阶段。本文分三个阶段来描述内核启动全过程。

- 第一阶段为内核自解压过 
- 第二阶段主要工作是设置 ARM 处理器工作模式、使能 MMU 、设置一级页表等，
- 第三阶段则主要为C代码，包括内核初始化的全部工作。

## Linux 内核自解压过程


在 BootLoader 完成系统的引导以后并将 Linux 内核调入内存之后，调用 `do_bootm_linux()`，这个函数将跳转到 kernel 的起始位置。如果 kernel 没有被压缩，就可以启动了。如果 kernel 被压缩过，则要进行解压，在压缩过的 kernel 头部有解压程序。压缩过的 kernel 入口第一个文件源码位置在 `./arch/arm64/kernel/head.S`。

解压缩代码位于 kernel/lib/inflate.c

head.S 中跳转到 start_kernel() 函数开始内核的初始化工作，在 head.S 中会检测机器码类型，	当检测处理器类型和机器码类型结束后，将调用 __create_page_tables 子函数来建立页表，它所要做的工作就是将 RAM 基地址开始的 1M 空间的物理地址映射到 0xC0000000 开始的虚拟地址处。当所有的初始化结束之后，使用如下代码来跳到 C 程序的入口函数 start_kernel()处，开始之后的内核初始化工作。

### 从start_kernel函数开始

start_kernel 是所有Linux 平台进入系统内核初始化后的入口函数，它主要完成剩余的与硬件平台相关的初始化工作，在进行一系列与内核相关的初始化后，调用第一个用户进程－ init 进程并等待用户进程的执行，这样整个  Linux 内核便启动完毕。该函数位于 `init/main.c` 文件中，主要工作流程如图 所示：

![](https://pic4.zhimg.com/80/v2-c95f7437e274147a90853acbe24df6d3_720w.jpg)

#### start_kernel 主要工作

1) 调用 setup_arch() 函数进行与体系结构相关的第一个初始化工作；对不同的体系结构来说该函数有不同的定义。对于ARM平台而言，该函数定义在 `arch/arm/kernel/setup.c` 。它首先通过检测出来的处理器类型进行处理器内核的初始化，然后对内存结构进行初始化，最后调用 paging_init() 开启 MMU，创建内核页表，映射所有的物理内存和 IO 空间。

2) 创建异常向量表和初始化中断处理函数；

3) 初始化系统核心进程调度器和时钟中断处理机制；

4) 初始化串口控制台（console_init）；

ARM-Linux 在初始化过程中一般都会初始化一个串口做为内核的控制台，而串口 Uart 驱动却把串口设备名写死了，如本例中 linux2.6.37 串口设备名为 ttyO0，而不是常用的 ttyS0。有了控制台内核在启动过程中就可以通过串口输出信息以便开发者或用户了解系统的启动进程。

5) 创建和初始化系统 cache，为各种内存调用机制提供缓存，包括;动态内存分配，虚拟文件系统（VirtualFile System ）及页缓存。

6) 初始化内存管理，检测内存大小及被内核占用的内存情况；

7) 初始化系统的进程间通信机制（IPC）； 
   
8) 当以上所有的初始化工作结束后， start_kernel() 函数会调用 `rest_init()` 函数来进行最后的初始化，包括创建系统的第一个进程－init 进程来结束内核的启动。

### 挂载根文件系统并启动 init

Linux 内核启动的下一过程是启动第一个进程 init ，但必须以根文件系统为载体，所以**在启动 init 之前，还要挂载根文件系统**。

以只读的方式挂载根文件系统，之所以采用只读的方式挂载根文件系统是因为：**此时Linux内核仍在启动阶段**，还不是很稳定，如果采用可读可写的方式挂载根文件系统，万一Linux不小心宕机了，一来可能破坏根文件系统上的数据，再者Linux下次开机时得花上很长的时间来检查并修复根文件系统。

挂载根文件系统的而目的有两个：一是安装适当的内核模块，以便驱动某些硬件设备或启用某些功能；二是启动存储于文件系统中的 init 服务，以便让 init服务接手后续的启动工作。

> https://zhuanlan.zhihu.com/p/456531995

## kernel 挂载文件系统

在 main.c 中的 kernel_init 线程函数中会调用 kernel_init_freeable() 函数，在 kernel_init_freeable 函数中将调用 prepare_namespace() 函数挂载指定的根文件系统

```c
  static noinline void __init kernel_init_freeable(void)
  {
    /*
     * Wait until kthreadd is all set-up.
     */
    wait_for_completion(&kthreadd_done);
   
    /* Now the scheduler is fully set up and can do blocking allocations */
    gfp_allowed_mask = __GFP_BITS_MASK;
   
    /*
     * init can allocate pages on any node
     */
    set_mems_allowed(node_states[N_MEMORY]);
   
    cad_pid = get_pid(task_pid(current));
   
    smp_prepare_cpus(setup_max_cpus);
   
    workqueue_init();
   
    init_mm_internals();
   
    do_pre_smp_initcalls();
    lockup_detector_init();
   
    smp_init();
    sched_init_smp();
   
    page_alloc_init_late();
    /* Initialize page ext after all struct pages are initialized. */
    page_ext_init();
   
    do_basic_setup();
   
    /* Open the /dev/console on the rootfs, this should never fail */
    if (ksys_open((const char __user *) "/dev/console", O_RDWR, 0) < 0)
      pr_err("Warning: unable to open an initial console.\n");
   
    (void) ksys_dup(0);
    (void) ksys_dup(0);
    /*
     * check if there is an early userspace init.  If yes, let it do all
     * the work
     */
   
    if (!ramdisk_execute_command)
      ramdisk_execute_command = "/init";
   
    if (ksys_access((const char __user *)
        ramdisk_execute_command, 0) != 0) {
      ramdisk_execute_command = NULL;
      prepare_namespace();     //挂载根文件系统
    }
   
    /*
     * Ok, we have completed the initial bootup, and
     * we're essentially up and running. Get rid of the
     * initmem segments and start the user-mode stuff..
     *
     * rootfs is available now, try loading the public keys
     * and default modules
     */
   
    integrity_load_keys();
    load_default_modules();
  } 
```

prepare_namespace 函数定义在（ /init/do_mounts.c ）文件中

```c
  void __init prepare_namespace(void)
  {           
    int is_floppy;
              
    if (root_delay) {
      printk(KERN_INFO "Waiting %d sec before mounting root device...\n",
             root_delay);
      ssleep(root_delay);
    }         
              
    /*        
     * wait for the known devices to complete their probing
     *        
     * Note: this is a potential source of long boot delays.
     * For example, it is not atypical to wait 5 seconds here
     * for the touchpad of a laptop to initialize.
     */       
	 //等待完成对已知设备的探测
    wait_for_device_probe();
              
    md_run_setup();
              
    if (saved_root_name[0]) {
      root_device_name = saved_root_name;
      if (!strncmp(root_device_name, "mtd", 3) ||
          !strncmp(root_device_name, "ubi", 3)) {
        mount_block_root(root_device_name, root_mountflags);
        goto out;
      }       
      ROOT_DEV = name_to_dev_t(root_device_name);
      if (strncmp(root_device_name, "/dev/", 5) == 0)
        root_device_name += 5;
    }         
              
    if (initrd_load())
      goto out;
              
    /* wait for any asynchronous scanning to complete */
	// 等待所有的异步扫描操作完成 
    if ((ROOT_DEV == 0) && root_wait) {
      printk(KERN_INFO "Waiting for root device %s...\n",
        saved_root_name);
      while (driver_probe_done() != 0 ||
        (ROOT_DEV = name_to_dev_t(saved_root_name)) == 0)
        msleep(5);
      async_synchronize_full();
    }         
              
    is_floppy = MAJOR(ROOT_DEV) == FLOPPY_MAJOR;
              
    if (is_floppy && rd_doload && rd_load_disk(0))
      ROOT_DEV = Root_RAM0;
              
    mount_root();
  out:        
    devtmpfs_mount("dev");
    ksys_mount(".", "/", NULL, MS_MOVE, NULL);
    ksys_chroot(".");
  }           
              
  static bool is_tmpfs;
  static struct dentry *rootfs_mount(struct file_system_type *fs_type,
    int flags, const char *dev_name, void *data)
  {           
    static unsigned long once;
    void *fill = ramfs_fill_super;
              
    if (test_and_set_bit(0, &once))
      return ERR_PTR(-ENODEV);
              
    if (IS_ENABLED(CONFIG_TMPFS) && is_tmpfs)
      fill = shmem_fill_super;
              
    return mount_nodev(fs_type, flags, data, fill);                                                                                 
  }  
```

上述代码本质是三种程序运行方式：

（1）【方式一】：如果 root_device_name 是 mtd 或者 ubi 类型的根设备，则调用 mount_block_root() 函数挂载文件系统。

（2）【方式二】：调用 initrd_load() 进行早期根文件系统的挂载，如果mount_initrd 为 true 的情况下，将执行根文件系统挂载操作。在 linux 内核中包含两种挂载早期根文件系统的机制：初始化 RAM 磁盘（initrd）是一种老式的机制。而 initramfs 是新的用于挂载早期根文件系统的机制。设计 initrd 和 initramfs 机制的目的：用于执行早期的用户空间程序；在挂载真正（最后的）根文件系统之前加载一些必须的设备驱动程序。

（3）【方式三】：调用 mount_root() 函数进行文件系统挂载。该种方式是linux 内核中比较常用的方式，在这种方式下，又包含三种文件系统挂载操作：1、nfs 方式。2、Floppy 方式。3、block 方式。在平时开发中，常使用 nfs 进行网络挂载根文件系统，以便进行开发和调试。

以上三种方式，在实际 linux 启动过程中，linux 内核将选择其中一种作为挂载根文件系统的方式。

> https://blog.csdn.net/iriczhao/article/details/122692264


## 参考资料

[Linux 内核启动及文件系统加载过程](https://zhuanlan.zhihu.com/p/456531995)

[kernel init函数之后](https://blog.csdn.net/jasonactions/article/details/111753936)

[start kernel专栏](https://blog.csdn.net/jasonactions/category_10653226.html)

[start kernel源码注释](https://blog.51cto.com/u_15635173/5417037)